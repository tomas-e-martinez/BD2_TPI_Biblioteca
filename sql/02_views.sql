CREATE VIEW VW_PrestamosActivos AS
SELECT P.IDPrestamo, (U.Nombre + ' ' + U.Apellido) AS Usuario, L.Titulo, P.FechaPrestamo, P.FechaDevolucion,
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
