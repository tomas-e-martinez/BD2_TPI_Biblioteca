--SCRIPT DE INSERCI�N DE DATOS DE PRUEBA

BEGIN TRY
	BEGIN TRANSACTION
		--AUTORES
		INSERT INTO Autores (Nombre, Apellido, Seudonimo)
		VALUES
			('Gabriel', 'Garc�a M�rquez', NULL),
			('J.K.', 'Rowling', NULL),
			('George', 'Orwell', NULL),
			('Isaac', 'Asimov', NULL),
			('Fi�dor', 'Dostoyevski', NULL),
			('Jane', 'Austen', NULL),
			('Haruki', 'Murakami', NULL),
			(NULL, NULL, 'Mark Twain'),
			(NULL, NULL, 'Lewis Carroll'),
			(NULL, NULL, 'L. Frank Baum');

		--CATEGOR�AS
		INSERT INTO Categorias (Descripcion)
		VALUES
			('Ficci�n'),
			('No Ficci�n'),
			('Ciencia Ficci�n'),
			('Suspenso'),
			('Rom�ntico'),
			('Historia'),
			('Fant�stico'),
			('Aventura'),
			('Terror'),
			('Biograf�a');

		--USUARIOS
		INSERT INTO Usuarios (DNI, Email, Nombre, Apellido, Telefono)
		VALUES
			('12345678', 'juan.perez@email.com', 'Juan', 'P�rez', '555-1234'),
			('87654321', 'maria.gomez@email.com', 'Mar�a', 'G�mez', '555-2345'),
			('11223344', 'luis.rodriguez@email.com', 'Luis', 'Rodr�guez', '555-3456'),
			('22334455', 'ana.martinez@email.com', 'Ana', 'Mart�nez', '555-4567'),
			('33445566', 'carlos.sanchez@email.com', 'Carlos', 'S�nchez', '555-5678'),
			('44556677', 'elena.ferrer@email.com', 'Elena', 'Ferrer', '555-6789'),
			('55667788', 'pedro.alvarez@email.com', 'Pedro', '�lvarez', '555-7890'),
			('66778899', 'sofia.lopez@email.com', 'Sof�a', 'L�pez', '555-8901'),
			('77889900', 'jorge.garcia@email.com', 'Jorge', 'Garc�a', '555-9012'),
			('88990011', 'lucia.morales@email.com', 'Luc�a', 'Morales', '555-0123'),
			('99001122', 'daniel.perez@email.com', 'Daniel', 'P�rez', '555-1234'),
			('10011223', 'veronica.rojas@email.com', 'Ver�nica', 'Rojas', '555-2345'),
			('11122334', 'martin.molina@email.com', 'Mart�n', 'Molina', '555-3456'),
			('12233445', 'silvia.gonzalez@email.com', 'Silvia', 'Gonz�lez', '555-4567'),
			('13344556', 'alfonso.torres@email.com', 'Alfonso', 'Torres', '555-5678'),
			('14455667', 'raquel.diaz@email.com', 'Raquel', 'D�az', '555-6789'),
			('15566778', 'ricardo.castro@email.com', 'Ricardo', 'Castro', '555-7890'),
			('16677889', 'marta.suarez@email.com', 'Marta', 'Su�rez', '555-8901'),
			('17788990', 'francisco.martinez@email.com', 'Francisco', 'Mart�nez', '555-9012'),
			('18899001', 'patricia.lopez@email.com', 'Patricia', 'L�pez', '555-0123');

		--LIBROS
		EXEC SP_InsertLibro @Titulo = 'Cien a�os de soledad', @AnioPublicacion = 1967, @Autores = '1', @Categorias = '1,6';
		EXEC SP_InsertLibro @Titulo = '1984', @AnioPublicacion = 1949, @Autores = '3', @Categorias = '1,3,4';
		EXEC SP_InsertLibro @Titulo = 'Orgullo y Prejuicio', @AnioPublicacion = 1813, @Autores = '6', @Categorias = '5,6';
		EXEC SP_InsertLibro @Titulo = 'Harry Potter y la piedra filosofal', @AnioPublicacion = 1997, @Autores = '2', @Categorias = '7,8';
		EXEC SP_InsertLibro @Titulo = 'Las aventuras de Tom Sawyer', @AnioPublicacion = 1876, @Autores = '8', @Categorias = '1,8';
		EXEC SP_InsertLibro @Titulo = 'Alicia en el pa�s de las maravillas', @AnioPublicacion = 1865, @Autores = '9', @Categorias = '7,8';
		EXEC SP_InsertLibro @Titulo = 'Fundaci�n', @AnioPublicacion = 1951, @Autores = '4', @Categorias = '3';
		EXEC SP_InsertLibro @Titulo = 'Kafka en la orilla', @AnioPublicacion = 2002, @Autores = '7', @Categorias = '1,7';

		--EJEMPLARES
		INSERT INTO Ejemplares (IDLibro, Estado, Observaciones)
		VALUES
			(1, 'Disponible', NULL),
			(1, 'Prestado', 'Leve desgaste en portada'),
			(2, 'Disponible', NULL),
			(2, 'Disponible', NULL),
			(3, 'Prestado', 'Manchas en las primeras p�ginas'),
			(4, 'Disponible', NULL),
			(4, 'Disponible', NULL),
			(4, 'Prestado', NULL),
			(5, 'Disponible', NULL),
			(6, 'Prestado', NULL),
			(7, 'Disponible', NULL),
			(7, 'Disponible', 'Edici�n especial'),
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