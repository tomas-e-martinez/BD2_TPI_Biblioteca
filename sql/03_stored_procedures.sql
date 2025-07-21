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