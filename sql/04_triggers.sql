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
