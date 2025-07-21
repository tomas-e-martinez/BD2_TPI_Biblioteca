-- ========================================
-- 1. CREACIÓN DE DB Y TABLAS
-- ========================================

--CREAR BASE DE DATOS SI NO EXISTE
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = 'BD2_TPI_Biblioteca')
BEGIN
	CREATE DATABASE [BD2_TPI_Biblioteca]
END
GO

--CAMBIAR AL CONTEXTO DE LA BASE DE DATOS CREADA
USE [BD2_TPI_Biblioteca]
GO

--CREAR TABLAS SI NO EXISTEN
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Libros')
BEGIN
	CREATE TABLE Libros(
		IDLibro INT PRIMARY KEY IDENTITY (1,1),
		Titulo NVARCHAR(255) NOT NULL,
		AnioPublicacion INT NULL
	)

	CREATE TABLE Categorias(
		IDCategoria INT PRIMARY KEY IDENTITY (1,1),
		Descripcion NVARCHAR(100) NOT NULL
	)

	CREATE TABLE Autores(
		IDAutor INT PRIMARY KEY IDENTITY (1,1),
		Nombre NVARCHAR(100) NULL,
		Apellido NVARCHAR(100) NULL,
		Seudonimo NVARCHAR(100) NULL,
		--NO PUEDEN SER NULL LOS 3 DATOS A LA VEZ
		CONSTRAINT CHK_Autor_NombreApellidoSeudonimo CHECK(
			Nombre IS NOT NULL OR Apellido IS NOT NULL OR Seudonimo IS NOT NULL
		)
	)

	CREATE TABLE Usuarios(
		IDUsuario INT PRIMARY KEY IDENTITY (1,1),
		Rol NVARCHAR(20) NOT NULL, 
		DNI NVARCHAR(20) NOT NULL UNIQUE,
		Email NVARCHAR(255) NOT NULL UNIQUE,
		Contrasena NVARCHAR(255) NOT NULL,
		Nombre NVARCHAR(100) NOT NULL,
		Apellido NVARCHAR(100) NOT NULL,
		Telefono NVARCHAR(20) NULL,
		CONSTRAINT CHK_Rol_Valido CHECK(
			Rol IN ('admin', 'cliente')
		)
	)

	CREATE TABLE LibroAutor(
		IDLibro INT NOT NULL,
		IDAutor INT NOT NULL,
		FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro) ON DELETE CASCADE,
		FOREIGN KEY (IDAutor) REFERENCES Autores(IDAutor) ON DELETE CASCADE,
		PRIMARY KEY (IDLibro, IDAutor)
	)

	CREATE TABLE LibroCategoria(
		IDLibro INT NOT NULL,
		IDCategoria INT NOT NULL,
		FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro) ON DELETE CASCADE,
		FOREIGN KEY (IDCategoria) REFERENCES Categorias(IDCategoria) ON DELETE CASCADE,
		PRIMARY KEY (IDLibro, IDCategoria)
	)

	CREATE TABLE Ejemplares(
		IDEjemplar INT PRIMARY KEY IDENTITY (1,1),
		IDLibro INT NOT NULL,
		Estado NVARCHAR(50) NOT NULL,
		Observaciones NVARCHAR(255) NULL,
		FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro) ON DELETE CASCADE
	)

	CREATE TABLE Prestamos(
		IDPrestamo INT PRIMARY KEY IDENTITY (1,1),
		IDCliente INT NOT NULL,
		IDAdmin INT NOT NULL,
		IDEjemplar INT NOT NULL,
		FechaPrestamo DATE NOT NULL DEFAULT GETDATE(),
		FechaDevolucion DATE NOT NULL,
		Devuelto BIT NOT NULL DEFAULT 0,
		FOREIGN KEY (IDCliente) REFERENCES Usuarios(IDUsuario),
		FOREIGN KEY (IDAdmin) REFERENCES Usuarios(IDUsuario),
		FOREIGN KEY (IDEjemplar) REFERENCES Ejemplares(IDEjemplar) ON DELETE CASCADE,
		CONSTRAINT CHK_FechaDevolucion CHECK (FechaDevolucion >= FechaPrestamo)
	)
END
GO




-- ========================================
-- 2. CREACIÓN DE VISTAS
-- ========================================

CREATE VIEW VW_HistorialPrestamos AS
SELECT 
	P.IDPrestamo,
	UA.IDUsuario AS IDAdmin,
	(UA.Nombre + ' ' + UA.Apellido) AS Administrador, 
	UC.IDUsuario AS IDCliente,
	(UC.Nombre + ' ' + UC.Apellido) AS Cliente, 
	P.IDEjemplar, 
	L.Titulo AS Libro, 
	P.FechaPrestamo, 
	P.FechaDevolucion, 
	P.Devuelto
FROM Prestamos P
INNER JOIN Usuarios UA ON P.IDAdmin = UA.IDUsuario
INNER JOIN Usuarios UC ON P.IDCliente = UC.IDUsuario
INNER JOIN Ejemplares E ON P.IDEjemplar = E.IDEjemplar
INNER JOIN Libros L ON E.IDLibro = L.IDLibro
GO


	
CREATE VIEW VW_PrestamosActivos AS
SELECT 
	*,
	CASE
		WHEN FechaDevolucion < GETDATE()
		THEN 1
		ELSE 0
	END AS Atrasado,
	CASE
		WHEN FechaDevolucion < GETDATE()
		THEN DATEDIFF(DAY, FechaDevolucion, GETDATE())
		ELSE NULL
	END AS DiasAtraso
FROM VW_HistorialPrestamos
WHERE Devuelto = 0
GO

	

CREATE VIEW VW_CantidadLibrosPorCategoria AS
SELECT 
    C.Descripcion AS Categoria,
    COUNT(DISTINCT LC.IDLibro) AS CantidadLibros,
	COUNT(E.IDEjemplar) AS CantidadEjemplares
FROM 
    Categorias C
LEFT JOIN 
    LibroCategoria LC ON C.IDCategoria = LC.IDCategoria
LEFT JOIN
	Libros L ON LC.IDLibro = L.IDLibro
LEFT JOIN
	Ejemplares E ON L.IDLibro = E.IDLibro
GROUP BY 
    C.Descripcion
GO



CREATE VIEW VW_LibrosDisponibles AS
SELECT 
	L.IDLibro,
	E.IDEjemplar,
    L.Titulo,
    L.AnioPublicacion AS AñoPublicacion,
    E.Estado,
    E.Observaciones
FROM Libros L
INNER JOIN Ejemplares E ON L.IDLibro = E.IDLibro
WHERE E.Estado = 'Disponible'
GO



-- ========================================
-- 3. CREACIÓN DE PROCEDIMIENTOS ALMACENADOS
-- ========================================

CREATE PROCEDURE SP_InsertLibro
	@Titulo NVARCHAR(255),
	@AnioPublicacion INT,
	@Autores NVARCHAR(MAX),
	@Categorias NVARCHAR(MAX)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			--INSERTAR LIBRO
			INSERT INTO Libros (Titulo, AnioPublicacion)
			VALUES (@Titulo, @AnioPublicacion)

			--OBTENER ID DEL LIBRO INSERTADO
			DECLARE @IDLibro INT = SCOPE_IDENTITY()

			--INSERTAR RELACIONES CON AUTORES
			DECLARE @IDAutor INT
			DECLARE @AutorCursor CURSOR

			SET @AutorCursor = CURSOR FOR
				SELECT value FROM STRING_SPLIT(@Autores, ',')

			OPEN @AutorCursor
			FETCH NEXT FROM @AutorCursor INTO @IDAutor

			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO LibroAutor (IDLibro, IDAutor)
				VALUES (@IDLibro, @IDAutor)
				FETCH NEXT FROM @AutorCursor INTO @IDAutor
			END

			CLOSE @AutorCursor
			DEALLOCATE @AutorCursor

			--INSERTAR RELACIONES CON CATEGORIAS
			DECLARE @IDCategoria INT
			DECLARE @CategoriaCursor CURSOR

			SET @CategoriaCursor = CURSOR FOR
				SELECT value FROM STRING_SPLIT(@Categorias, ',')

			OPEN @CategoriaCursor
			FETCH NEXT FROM @CategoriaCursor INTO @IDCategoria

			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO LibroCategoria (IDLibro, IDCategoria)
				VALUES (@IDLibro, @IDCategoria)
				FETCH NEXT FROM @CategoriaCursor INTO @IDCategoria
			END

			CLOSE @CategoriaCursor
			DEALLOCATE @CategoriaCursor
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION
			PRINT ERROR_MESSAGE()
			RAISERROR('ERROR AL INSERTAR EL LIBRO', 16, 1)
		END
	END CATCH
END
GO

CREATE PROCEDURE SP_CategoriaConMasPrestamosPorAnio
    @Anio INT
AS
BEGIN
    SELECT TOP 1
        C.Descripcion AS Categoria,
        COUNT(*) AS CantidadPrestamos
    FROM Prestamos P
    JOIN Ejemplares E ON P.IDEjemplar = E.IDEjemplar
    JOIN Libros L ON E.IDLibro = L.IDLibro
    JOIN LibroCategoria LC ON L.IDLibro = LC.IDLibro
    JOIN Categorias C ON LC.IDCategoria = C.IDCategoria
    WHERE YEAR(P.FechaPrestamo) = @Anio
    GROUP BY C.Descripcion
    ORDER BY COUNT(*) DESC
END
GO

CREATE PROCEDURE SP_LibrosConMasPrestamosPorRangoFechas
	@Desde DATE,
	@Hasta DATE
AS
BEGIN
	SELECT
		L.IDLibro,
		L.Titulo,
		COUNT(*) AS CantidadPrestamos
	FROM Prestamos P
	INNER JOIN Ejemplares E ON P.IDEjemplar = E.IDEjemplar
	INNER JOIN Libros L ON E.IDLibro = L.IDLibro
	WHERE P.FechaPrestamo BETWEEN @Desde AND @Hasta
	GROUP BY L.IDLibro, L.Titulo
	ORDER BY CantidadPrestamos DESC
END
GO

-- ========================================
-- 4. CREACIÓN DE TRIGGERS
-- ========================================

CREATE TRIGGER TR_ActualizarEstadoEjemplar
ON Prestamos
AFTER INSERT
AS
BEGIN
	UPDATE E
	SET E.Estado = 'Prestado'
	FROM Ejemplares E
	INNER JOIN inserted I ON E.IDEjemplar = I.IDEjemplar
END
GO

CREATE TRIGGER TR_RestaurarEstadoEjemplar
ON Prestamos
AFTER DELETE
AS
BEGIN
	UPDATE E
	SET E.Estado = 'Disponible'
	FROM Ejemplares E
	INNER JOIN deleted D ON E.IDEjemplar = D.IDEjemplar
	WHERE D.Devuelto = 0 --SOLO ACTUALIZA SI EL PRÉSTAMO NO FUE DEVUELTO (ES DECIR, SE ABORTÓ)
END
GO

CREATE TRIGGER TR_ActualizarEjemplarPrestamoDevuelto
ON Prestamos
AFTER UPDATE
AS
BEGIN
	UPDATE E
	SET E.Estado = 'Disponible'
	FROM Ejemplares E
	INNER JOIN inserted I ON E.IDEjemplar = I.IDEjemplar
	INNER JOIN deleted D ON E.IDEjemplar = D.IDEjemplar
	WHERE I.Devuelto = 1 AND D.Devuelto = 0
END
GO

CREATE TRIGGER TR_ValidarAdminInsert
ON Prestamos
INSTEAD OF INSERT
AS
BEGIN
	--VALIDAR QUE TODOS LOS IDADMIN INGRESADOS PERTENEZCAN A UN USUARIO CON ROL 'ADMIN'
	IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM Usuarios u
            WHERE u.IDUsuario = i.IDAdmin AND u.Rol = 'admin'
        )
    )

	BEGIN
		INSERT INTO Prestamos (IDCliente, IDAdmin, IDEjemplar, FechaPrestamo, FechaDevolucion, Devuelto)
		SELECT IDCliente, IDAdmin, IDEjemplar, FechaPrestamo, FechaDevolucion, Devuelto
		FROM inserted
	END
	ELSE
	BEGIN
		RAISERROR('EL IDADMIN DEBE PERTENECER A UN USUARIO CON EL ROL "ADMIN"', 16, 1)
	END
END
GO



-- ========================================
-- 5. INSERCIÓN DE DATOS DE PRUEBA
-- ========================================

BEGIN TRY
	BEGIN TRANSACTION
		--AUTORES
		INSERT INTO Autores (Nombre, Apellido, Seudonimo)
		VALUES
			('Gabriel', 'García Márquez', NULL),
			('J.K.', 'Rowling', NULL),
			('George', 'Orwell', NULL),
			('Isaac', 'Asimov', NULL),
			('Fiódor', 'Dostoyevski', NULL),
			('Jane', 'Austen', NULL),
			('Haruki', 'Murakami', NULL),
			(NULL, NULL, 'Mark Twain'),
			(NULL, NULL, 'Lewis Carroll'),
			(NULL, NULL, 'L. Frank Baum');

		--CATEGORÍAS
		INSERT INTO Categorias (Descripcion)
		VALUES
			('Ficción'),
			('No Ficción'),
			('Ciencia Ficción'),
			('Suspenso'),
			('Romántico'),
			('Historia'),
			('Fantástico'),
			('Aventura'),
			('Terror'),
			('Biografía');

		--USUARIOS
		INSERT INTO Usuarios (Rol, DNI, Email, Contrasena, Nombre, Apellido, Telefono)
		VALUES
			('admin',   '12345678', 'juan.perez@email.com',     'pass123', 'Juan',     'Pérez',    '555-1234'),
			('admin',   '87654321', 'maria.gomez@email.com',    'pass123', 'María',    'Gómez',    '555-2345'),
			('cliente', '11223344', 'luis.rodriguez@email.com', 'pass123', 'Luis',     'Rodríguez','555-3456'),
			('cliente', '22334455', 'ana.martinez@email.com',   'pass123', 'Ana',      'Martínez', '555-4567'),
			('cliente', '33445566', 'carlos.sanchez@email.com', 'pass123', 'Carlos',   'Sánchez',  '555-5678'),
			('cliente', '44556677', 'elena.ferrer@email.com',   'pass123', 'Elena',    'Ferrer',   '555-6789'),
			('cliente', '55667788', 'pedro.alvarez@email.com',  'pass123', 'Pedro',    'Álvarez',  '555-7890'),
			('cliente', '66778899', 'sofia.lopez@email.com',    'pass123', 'Sofía',    'López',    '555-8901'),
			('cliente', '77889900', 'jorge.garcia@email.com',   'pass123', 'Jorge',    'García',   '555-9012'),
			('cliente', '88990011', 'lucia.morales@email.com',  'pass123', 'Lucía',    'Morales',  '555-0123'),
			('cliente', '99001122', 'daniel.perez@email.com',   'pass123', 'Daniel',   'Pérez',    '555-1234'),
			('cliente', '10011223', 'veronica.rojas@email.com', 'pass123', 'Verónica', 'Rojas',    '555-2345'),
			('cliente', '11122334', 'martin.molina@email.com',  'pass123', 'Martín',   'Molina',   '555-3456'),
			('cliente', '12233445', 'silvia.gonzalez@email.com','pass123', 'Silvia',   'González', '555-4567'),
			('cliente', '13344556', 'alfonso.torres@email.com', 'pass123', 'Alfonso',  'Torres',   '555-5678'),
			('cliente', '14455667', 'raquel.diaz@email.com',    'pass123', 'Raquel',   'Díaz',     '555-6789'),
			('cliente', '15566778', 'ricardo.castro@email.com', 'pass123', 'Ricardo',  'Castro',   '555-7890'),
			('cliente', '16677889', 'marta.suarez@email.com',   'pass123', 'Marta',    'Suárez',   '555-8901'),
			('cliente', '17788990', 'francisco.martinez@email.com','pass123','Francisco','Martínez','555-9012'),
			('cliente', '18899001', 'patricia.lopez@email.com', 'pass123', 'Patricia', 'López',    '555-0123');

		--LIBROS
		EXEC SP_InsertLibro @Titulo = 'Cien años de soledad', @AnioPublicacion = 1967, @Autores = '1', @Categorias = '1,6';
		EXEC SP_InsertLibro @Titulo = '1984', @AnioPublicacion = 1949, @Autores = '3', @Categorias = '1,3,4';
		EXEC SP_InsertLibro @Titulo = 'Orgullo y Prejuicio', @AnioPublicacion = 1813, @Autores = '6', @Categorias = '5,6';
		EXEC SP_InsertLibro @Titulo = 'Harry Potter y la piedra filosofal', @AnioPublicacion = 1997, @Autores = '2', @Categorias = '7,8';
		EXEC SP_InsertLibro @Titulo = 'Las aventuras de Tom Sawyer', @AnioPublicacion = 1876, @Autores = '8', @Categorias = '1,8';
		EXEC SP_InsertLibro @Titulo = 'Alicia en el país de las maravillas', @AnioPublicacion = 1865, @Autores = '9', @Categorias = '7,8';
		EXEC SP_InsertLibro @Titulo = 'Fundación', @AnioPublicacion = 1951, @Autores = '4', @Categorias = '3';
		EXEC SP_InsertLibro @Titulo = 'Kafka en la orilla', @AnioPublicacion = 2002, @Autores = '7', @Categorias = '1,7';

		--EJEMPLARES
		INSERT INTO Ejemplares (IDLibro, Estado, Observaciones)
		VALUES
			(1, 'Prestado', NULL),                            -- IDEjemplar = 1
			(1, 'Disponible', 'Leve desgaste en portada'),    -- IDEjemplar = 2
			(2, 'Prestado', NULL),                            -- IDEjemplar = 3
			(2, 'Disponible', NULL),                          -- IDEjemplar = 4
			(3, 'Prestado', 'Manchas en las primeras páginas'),-- IDEjemplar = 5
			(4, 'Disponible', NULL),                          -- IDEjemplar = 6
			(4, 'Prestado', NULL),                            -- IDEjemplar = 7
			(4, 'Disponible', NULL),                          -- IDEjemplar = 8
			(5, 'Disponible', NULL),                          -- IDEjemplar = 9
			(6, 'Disponible', NULL),                          -- IDEjemplar = 10
			(7, 'Disponible', NULL),                          -- IDEjemplar = 11
			(7, 'Disponible', 'Edición especial'),            -- IDEjemplar = 12
			(8, 'Prestado', NULL);							  -- IDEjemplar = 13

		--PRESTAMOS
		INSERT INTO Prestamos (IDCliente, IDAdmin, IDEjemplar, FechaPrestamo, FechaDevolucion, Devuelto)
		VALUES 
			(3, 1,  1, '2025-06-01', '2025-06-15', 0),
			(4, 1,  2, '2025-06-02', '2025-06-16', 1),
			(4, 2, 13, '2025-06-19', '2025-07-03', 0),
			(5, 1,  3, '2025-06-05', '2025-06-19', 0),
			(6, 2,  4, '2025-06-06', '2025-06-20', 1),
			(7, 1,  5, '2025-06-07', '2025-06-21', 0),
			(8, 2,  6, '2025-06-08', '2025-06-22', 1),
			(9, 1,  7, '2025-06-09', '2025-06-23', 0),
			(10, 2, 8, '2025-06-10', '2025-06-24', 1);

		UPDATE Ejemplares SET Estado = 'Disponible' WHERE IDEjemplar IN (SELECT IDEjemplar FROM Prestamos WHERE Devuelto = 1);
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION
	END
	PRINT ERROR_MESSAGE()
	RAISERROR('ERROR AL INSERTAR DATOS DE PRUEBA', 16, 1)
END CATCH