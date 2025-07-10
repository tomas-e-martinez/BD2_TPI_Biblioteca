--SCRIPT DE INSERCIÓN DE DATOS DE PRUEBA

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