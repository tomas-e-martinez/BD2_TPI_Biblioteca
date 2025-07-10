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
