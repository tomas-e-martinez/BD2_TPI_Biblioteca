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
	L.IDLibro,
	E.IDEjemplar,
    L.Titulo,
    L.AnioPublicacion AS AñoPublicacion,
    E.Estado,
    E.Observaciones
FROM Libros L
INNER JOIN Ejemplares E ON L.IDLibro = E.IDLibro
WHERE E.Estado = 'Disponible'