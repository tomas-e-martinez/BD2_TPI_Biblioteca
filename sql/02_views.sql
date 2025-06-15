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

