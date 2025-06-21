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
		DNI NVARCHAR(20) NOT NULL UNIQUE,
		Email NVARCHAR(255) NOT NULL,
		Nombre NVARCHAR(100) NOT NULL,
		Apellido NVARCHAR(100) NOT NULL,
		Telefono NVARCHAR(20) NULL
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
		IDUsuario INT NOT NULL,
		IDEjemplar INT NOT NULL,
		FechaPrestamo DATE NOT NULL,
		FechaDevolucion DATE NOT NULL,
		Devuelto BIT NOT NULL,
		FOREIGN KEY (IDUsuario) REFERENCES Usuarios(IDUsuario) ON DELETE CASCADE,
		FOREIGN KEY (IDEjemplar) REFERENCES Ejemplares(IDEjemplar) ON DELETE CASCADE
	)
END
GO


-- ========================================
-- 2. CREACIÓN DE VISTAS
-- ========================================

CREATE VIEW VW_PrestamosActivos AS
SELECT 
	P.IDPrestamo, 
	(U.Nombre + ' ' + U.Apellido) AS Usuario, 
	L.Titulo, 
	P.FechaPrestamo, 
	P.FechaDevolucion,
	CASE
		WHEN P.FechaDevolucion < GETDATE()
		THEN 1
		ELSE 0
	END AS Atrasado,
	CASE
		WHEN P.FechaDevolucion < GETDATE()
		THEN DATEDIFF(DAY, P.FechaDevolucion, GETDATE())
		ELSE NULL
	END AS DiasAtraso
FROM Prestamos P
INNER JOIN Usuarios U ON P.IDUsuario = U.IDUsuario
INNER JOIN Ejemplares E ON P.IDEjemplar = E.IDEjemplar
INNER JOIN Libros L ON E.IDLibro = L.IDLibro
WHERE P.Devuelto = 0
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
    L.Titulo,
    L.AnioPublicacion,
    E.IDEjemplar,
    E.Estado,
    E.Observaciones
FROM Libros L
INNER JOIN Ejemplares E ON L.IDLibro = E.IDLibro
WHERE E.Estado = 'Disponible' 
AND E.IDEjemplar NOT IN (
    SELECT P.IDEjemplar 
    FROM Prestamos P 
    WHERE P.Devuelto = 0
)
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

CREATE PROCEDURE SP_ListarPrestamosPorUsuario
	@IDUsuario INT,
	@Devuelto BIT = NULL
AS
BEGIN
	BEGIN TRY
		SELECT 
			P.IDPrestamo, 
			P.FechaPrestamo, 
			P.FechaDevolucion, 
			L.Titulo AS Libro, 
			E.IDEjemplar, 
			E.Estado
		FROM Prestamos P
		INNER JOIN Ejemplares E ON P.IDEjemplar = E.IDEjemplar
		INNER JOIN Libros L ON E.IDLibro = L.IDLibro
		WHERE P.IDUsuario = @IDUsuario
		AND (@Devuelto IS NULL OR P.Devuelto = @Devuelto)
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
		RAISERROR('ERROR AL GENERAR REPORTE', 16, 1)
	END CATCH
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



-- ========================================
-- 4. INSERCIÓN DE DATOS DE PRUEBA
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
		INSERT INTO Usuarios (DNI, Email, Nombre, Apellido, Telefono)
		VALUES
			('12345678', 'juan.perez@email.com', 'Juan', 'Pérez', '555-1234'),
			('87654321', 'maria.gomez@email.com', 'María', 'Gómez', '555-2345'),
			('11223344', 'luis.rodriguez@email.com', 'Luis', 'Rodríguez', '555-3456'),
			('22334455', 'ana.martinez@email.com', 'Ana', 'Martínez', '555-4567'),
			('33445566', 'carlos.sanchez@email.com', 'Carlos', 'Sánchez', '555-5678'),
			('44556677', 'elena.ferrer@email.com', 'Elena', 'Ferrer', '555-6789'),
			('55667788', 'pedro.alvarez@email.com', 'Pedro', 'Álvarez', '555-7890'),
			('66778899', 'sofia.lopez@email.com', 'Sofía', 'López', '555-8901'),
			('77889900', 'jorge.garcia@email.com', 'Jorge', 'García', '555-9012'),
			('88990011', 'lucia.morales@email.com', 'Lucía', 'Morales', '555-0123'),
			('99001122', 'daniel.perez@email.com', 'Daniel', 'Pérez', '555-1234'),
			('10011223', 'veronica.rojas@email.com', 'Verónica', 'Rojas', '555-2345'),
			('11122334', 'martin.molina@email.com', 'Martín', 'Molina', '555-3456'),
			('12233445', 'silvia.gonzalez@email.com', 'Silvia', 'González', '555-4567'),
			('13344556', 'alfonso.torres@email.com', 'Alfonso', 'Torres', '555-5678'),
			('14455667', 'raquel.diaz@email.com', 'Raquel', 'Díaz', '555-6789'),
			('15566778', 'ricardo.castro@email.com', 'Ricardo', 'Castro', '555-7890'),
			('16677889', 'marta.suarez@email.com', 'Marta', 'Suárez', '555-8901'),
			('17788990', 'francisco.martinez@email.com', 'Francisco', 'Martínez', '555-9012'),
			('18899001', 'patricia.lopez@email.com', 'Patricia', 'López', '555-0123');

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
			(1, 'Disponible', NULL),
			(1, 'Prestado', 'Leve desgaste en portada'),
			(2, 'Disponible', NULL),
			(2, 'Disponible', NULL),
			(3, 'Prestado', 'Manchas en las primeras páginas'),
			(4, 'Disponible', NULL),
			(4, 'Disponible', NULL),
			(4, 'Prestado', NULL),
			(5, 'Disponible', NULL),
			(6, 'Prestado', NULL),
			(7, 'Disponible', NULL),
			(7, 'Disponible', 'Edición especial'),
			(8, 'Disponible', NULL);

		--PRESTAMOS
		INSERT INTO Prestamos (IDUsuario, IDEjemplar, FechaPrestamo, FechaDevolucion, Devuelto)
		VALUES 
			(1, 1, '2025-06-01', '2025-06-15', 0),
			(2, 2, '2025-06-02', '2025-06-16', 1),
			(3, 3, '2025-06-05', '2025-06-19', 0),
			(4, 4, '2025-06-06', '2025-06-20', 1),
			(5, 5, '2025-06-07', '2025-06-21', 0),
			(6, 6, '2025-06-08', '2025-06-22', 1),
			(7, 7, '2025-06-09', '2025-06-23', 0),
			(8, 8, '2025-06-10', '2025-06-24', 1);
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