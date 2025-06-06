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