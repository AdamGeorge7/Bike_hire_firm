USE [master]

GO
CREATE DATABASE [Bike_hire_app]

GO
USE [Bike_hire_app]


-- ============================================================================================TABLES===============================================================================================================

GO
CREATE TABLE [dbo].[Bases](
	[base_id] [int] IDENTITY(1,1) NOT NULL,
	[address] [varchar](50) NOT NULL,
	[zip_code] [varchar](50) CHECK (LEN(zip_code) = 6),
	[city] [varchar](50) NOT NULL,
    [is_delted] [bit]
	PRIMARY KEY (base_id)
)

GO
CREATE TABLE [dbo].[User_type](
    [user_type_id] [int] IDENTITY(1,1) NOT NULL,
    [user_type] [varchar](50) NOT NULL
    PRIMARY KEY (user_type_id)
)

GO
CREATE TABLE [dbo].[Service_companies](
	[service_cmp_id] [int] IDENTITY(1,1) NOT NULL,
	[company_name] [varchar](50) NOT NULL,
    [is_delted] [bit],
	PRIMARY KEY (service_cmp_id)
)

GO
CREATE TABLE [dbo].[Users](
	[user__id] [int] IDENTITY(1,1) NOT NULL,
    [login] [varchar](50) NOT NULL,
    [user_password] [varchar](50) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[surname] [varchar](50) NOT NULL,
	[tel_nr] [varchar](50) NOT NULL,
	[email] [varchar](50) NOT NULL,
	[pesel] [varchar](50) CHECK (LEN(pesel) = 11),
    [user_type_id] [int] NOT NULL,
    [is_delted] [bit],
	PRIMARY KEY (user__id),
    FOREIGN KEY (user_type_id) REFERENCES User_type (user_type_id)
)

GO
CREATE TABLE [dbo].[Servicemen](
	[serviceman_id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[surname] [varchar](50) NOT NULL,
	[salary] [money] NOT NULL,
	[service_cmp_id] [int] NOT NULL,
    [is_delted] [bit],
	PRIMARY KEY (serviceman_id),
	FOREIGN KEY (service_cmp_id) REFERENCES Service_companies (service_cmp_id)
)

GO
CREATE TABLE [dbo].[Bikes](
	[bike_id] [int] IDENTITY(1,1) NOT NULL,
	[price_per_day] [money] NOT NULL,
	[base_id] [int] NOT NULL,
    [availability] [varchar](50),
	PRIMARY KEY (bike_id),
	FOREIGN KEY (base_id) REFERENCES Bases (base_id)
)

GO
CREATE TABLE [dbo].[Services](
	[service_id] [int] IDENTITY(1,1) NOT NULL,
	[start_date] [date] NOT NULL,
	[finish_date] [date] NOT NULL,
	[bill_nr] [varchar](50) NOT NULL,
    [service_done] [bit],
	[bike_id] [int] NOT NULL,
	[service_cmp_id] [int] NOT NULL,
	PRIMARY KEY (service_id),
	FOREIGN KEY (bike_id) REFERENCES Bikes (bike_id),
	FOREIGN KEY (service_cmp_id) REFERENCES Service_companies (service_cmp_id)
)

GO
CREATE TABLE [dbo].[Rentals](
	[rental_id] [int] IDENTITY(1,1) NOT NULL,
	[start_date] [date] NOT NULL,
	[finish_date] [date] NOT NULL,
	[charge] [money] NOT NULL,
    [rental_done] [bit],
	[bike_id] [int] NOT NULL,
	[user__id] [int] NOT NULL,
	PRIMARY KEY (rental_id),
	FOREIGN KEY (bike_id) REFERENCES Bikes (bike_id),
	FOREIGN KEY (user__id) REFERENCES Users (user__id)
)

GO
CREATE TABLE [dbo].[Transport]( 
    [transport_id] [int] IDENTITY(1,1) NOT NULL,
    [transport_done] [bit],
    [bike_id] [int] NOT NULL,
    [base_id_from] [int] NOT NULL,
    [base_id_to] [int] NOT NULL,
    FOREIGN KEY (bike_id) REFERENCES Bikes (bike_id),
    FOREIGN KEY (base_id_from) REFERENCES Bases (base_id),
    FOREIGN KEY (base_id_to) REFERENCES Bases (base_id)
)












-- =============================================================================================PROCEDURES=======================================================================================================

-- -----------------------------------------------------------------------------------------------CREATE----------------------------------------------------------------------------------------------------
-- --------------CREATE BIKE--------------

CREATE PROCEDURE AddBike @price_per_day money, @base_id int
AS
BEGIN
	IF(exists (SELECT * FROM Bases WHERE base_id = @base_id))
	BEGIN		
		INSERT INTO [dbo].[Bikes]
		VALUES (@price_per_day, @base_id, 'available', 0);
		PRINT 'Bike has been added succesfully. ';
    END
	ELSE
		RAISERROR ('There is not such a base. ', -1, -1, 'AddBike')
END




-- --------------CREATE USER--------------

CREATE PROCEDURE CreateAccount @login varchar(50), @user_password varchar(50), @name varchar(50), @surname varchar(50), @tel_nr varchar(50), @email varchar(50), @pesel varchar(50), @user_type_id int
AS
BEGIN
	IF(len(@user_password) < 5)
	BEGIN
		RAISERROR ('Password is too short. ', -1, -1, 'CreateAccount')
	END
	ELSE
	BEGIN
		IF(exists (SELECT * FROM Users WHERE login = @login))
		BEGIN
			RAISERROR ('There is such a login. ', -1, -1, 'CreateAccount')
		END
		ELSE
		BEGIN
			if(@user_password LIKE '% %')
			BEGIN
				RAISERROR ('There must not be any spaces in a password. ', -1, -1, 'CreateAccount')
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[Users]
				VALUES (@login, CONVERT(varchar(32), HashBytes('MD5', @user_password), 2), @name, @surname, @tel_nr, @email, @pesel, 1, 0);
			END
		END
	END
END




-- --------------CREATE & ACCOMPLISH RENTAL--------------

CREATE PROCEDURE CreateRental @bike_id int, @user__id int
AS
BEGIN
    DECLARE @start_finish_date date;
	IF(not exists (SELECT * FROM Users WHERE user__id = @user__id))
	BEGIN
		RAISERROR ('There is not such a user. ', -1, -1, 'CreateRental')
	END
	ELSE
	BEGIN
		IF (exists (SELECT * FROM Rentals WHERE user__id = @user__id AND rental_done = 0))
		BEGIN
			RAISERROR ('You must return bike in order to rent the other one. ', -1, -1, 'CreateRental')
		END
		ELSE
		BEGIN
			IF(not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id)) 
			BEGIN
				RAISERROR ('There is not such a bike. ', -1, -1, 'CreateRental')
			END
			ELSE
			BEGIN
				IF ((SELECT availability FROM Bikes WHERE bike_id = @bike_id) != 'available')
				BEGIN
					RAISERROR ('There is not such a bike available. ', -1, -1, 'CreateRental')
				END
				ELSE
				BEGIN
					SET @start_finish_date = CONVERT (date, SYSDATETIME());
					UPDATE Bikes
					SET availability = 'non-available'
					WHERE bike_id = @bike_id;
					INSERT INTO [dbo].[Rentals]
					VALUES (@start_finish_date, (SELECT DATEADD(day, 1, @start_finish_date)), 0, 0, @bike_id, @user__id);
				END
			END
		END
	END
END

--

CREATE PROCEDURE AccomplishRental @user__id int, @bike_id int, @base_id int 
AS
BEGIN
    DECLARE @charge money;
    DECLARE @DateDiff int;
    DECLARE @finish_date date;
	IF(not exists (SELECT * FROM Users WHERE user__id = @user__id))
	BEGIN
		RAISERROR ('There is not such a user. ', -1, -1, 'AccomplishRental')
	END
	ELSE
	BEGIN
		IF(exists (SELECT * FROM Rentals WHERE bike_id = @bike_id AND (SELECT availability FROM Bikes WHERE bike_id = @bike_id) = 'non-available' AND rental_done = 0))
		BEGIN
			SET @finish_date = CONVERT (date, SYSDATETIME());
			SELECT @DateDiff = DATEDIFF(DAY, (SELECT start_date FROM Rentals WHERE bike_id = @bike_id AND rental_done = 0), @finish_date);
			IF (@DateDiff != 0)
			BEGIN
				SET @charge = (SELECT price_per_day FROM Bikes WHERE bike_id = @bike_id) * @DateDiff;
			END
			ELSE
			BEGIN
				SET @charge = (SELECT price_per_day FROM Bikes WHERE bike_id = @bike_id);
			END
			UPDATE Bikes
			SET availability = 'available', base_id = @base_id
			WHERE bike_id = @bike_id;
			UPDATE Rentals
			SET finish_date = @finish_date, charge = @charge, rental_done = 1
			WHERE bike_id = @bike_id AND user__id = @user__id AND rental_done = 0;
		END
		ELSE
		BEGIN
			RAISERROR ('There is not such a rental. ', -1, -1, 'AccomplishRental')
		END
	END
END




-- --------------CREATE USER TYPE--------------

CREATE PROCEDURE CreateUserType @user_type varchar(50)
AS
BEGIN
    IF (not exists (SELECT * FROM User_type WHERE @user_type = user_type))
    BEGIN
        INSERT INTO [dbo].[User_type]
        VALUES (@user_type);
	END
    ELSE
    BEGIN
        RAISERROR ('There is such a user type. ', -1, -1, 'CreateUserType')
    END
END




-- --------------CREATE BASE--------------

CREATE PROCEDURE AddBase @address varchar(50), @zip_code varchar(50), @city varchar(50)
AS
BEGIN
    IF (not exists (SELECT * FROM Bases WHERE address = @address AND zip_code = @zip_code AND city = @city))
    BEGIN
        INSERT INTO [dbo].[Bases]
        VALUES (@address, @zip_code, @city, 0);
	END
    ELSE
    BEGIN
        RAISERROR ('There is such a base. ', -1, -1, 'AddBase')
    END
END




-- --------------CREATE SERVICEMAN--------------

CREATE PROCEDURE AddServiceman @name varchar(50), @surname varchar(50), @salary money, @service_cmp_id int
AS
BEGIN
    INSERT INTO [dbo].[Servicemen]
    VALUES (@name, @surname, @salary, @service_cmp_id, 0);
END




-- --------------CREATE SERVICE COMPANIES--------------

CREATE PROCEDURE AddServiceCompany @company_name varchar(50)
AS
BEGIN
    IF (not exists (SELECT * FROM Service_companies WHERE company_name = @company_name))
    BEGIN
        INSERT INTO [dbo].[Service_companies]
        VALUES (@company_name, 0);
	END
    ELSE
    BEGIN
        RAISERROR ('There is such a company. ', -1, -1, 'AddServiceCompany')
    END
END



-- --------------CREATE & ACCOMPLISH SERVICE--------------

CREATE PROCEDURE CreateService @bike_id int, @service_cmp_id int
AS
BEGIN
    DECLARE @start_finish_date date;
    IF (not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id)) 
    BEGIN
        RAISERROR ('There is not such a bike. ', -1, -1, 'CreateService')
	END
    ELSE
    BEGIN
        IF (not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id AND availability = 'available'))
        BEGIN
            RAISERROR ('There is not such a bike available. ', -1, -1, 'CreateService')
		END
		ELSE
        BEGIN
            IF (not exists (SELECT * FROM Service_companies WHERE service_cmp_id = @service_cmp_id))
            BEGIN
                RAISERROR ('There is not such a company', -1, -1, 'CreateService')
			END
            ELSE
            BEGIN
                SET @start_finish_date = CONVERT (date, SYSDATETIME());
                UPDATE Bikes
                SET availability = 'service'
                WHERE bike_id = @bike_id;
                INSERT INTO [dbo].[Services]
                VALUES (@start_finish_date, (SELECT DATEADD(day, 1, @start_finish_date)), 0, 0, @bike_id, @service_cmp_id)
            END
        END
    END
END

-- --

CREATE PROCEDURE AccomplishService @bike_id int, @service_cmp_id int, @bill_nr varchar (50), @base_id int
AS
BEGIN
    DECLARE @finish_date date;
    IF (not exists (SELECT * FROM Services WHERE bike_id = @bike_id AND service_done = 0) AND not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id AND availability = 'service'))
    BEGIN
        RAISERROR ('There is not such a service. ', -1, -1, 'AccomplishService')
    ELSE
    BEGIN
        IF (not exists(SELECT * FROM Bases WHERE base_id = @base_id))
        BEGIN
            RAISERROR ('There is not such a base. ', -1, -1, 'CreateTransport')
		END
        ELSE
        BEGIN
            SET @finish_date = CONVERT (date, SYSDATETIME());
            UPDATE Bikes
            SET availability = 'available', base_id = @base_id
            WHERE bike_id = @bike_id;
            UPDATE Services
            SET finish_date = @finish_date, bill_nr = @bill_nr, service_done = 1
            WHERE bike_id = @bike_id AND service_cmp_id = @service_cmp_id AND service_done = 0;
        END
    END
END



-- --------------CREATE & ACCOMPLISH TRANSPORT--------------

CREATE PROCEDURE CreateTransport @bike_id int, @base_id_to int
AS
BEGIN
    IF (not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id AND availability = 'available'))
    BEGIN
        RAISERROR ('There is not such a bike. ', -1, -1, 'CreateTransport')
    END
    ELSE
    BEGIN
        IF (not exists(SELECT * FROM Bases WHERE base_id = @base_id_to))
        BEGIN
            RAISERROR ('There is not such a base. ', -1, -1, 'CreateTransport')
		END
        ELSE
        BEGIN
            UPDATE Bikes
            SET availability = 'transport'
            WHERE bike_id = @bike_id;
            INSERT INTO [dbo].[Transport]
            VALUES (0, @bike_id, (SELECT base_id FROM Bikes WHERE bike_id = @bike_id), @base_id_to);
        END
    END
END

-- --

CREATE PROCEDURE AccomplishTransport @bike_id int
AS
BEGIN
    IF (not exists(SELECT * FROM Bikes WHERE bike_id = @bike_id AND availability = 'transport') AND (SELECT * FROM Transport WHERE bike_id = @bike_id AND transport_done = 0)
    BEGIN
        RAISERROR ('There is not such a bike. ', -1, -1, 'CreateTransport')
    END
    ELSE
    BEGIN
        UPDATE Bikes
        SET availability = 'available'
        WHERE bike_id = @bike_id;
        UPDATE Transport
        SET transport_done = 1
        WHERE bike_id = @bike_id AND transport_done = 0;
    END
END
    
    

-- ----------------------------------------------------------------------------------------------UPDATE-------------------------------------------------------------------------------------------------------------

-- --------------UPDATE USER TYPE FOR A USER--------------

CREATE PROCEDURE ChangeUserType @user__id int, @user_type_id int
AS
BEGIN
    if (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET user_type_id = @user_type_id
        WHERE user__id = @user__id
    END
    ELSE
    BEGIN
        RAISERROR ('There is not such an user. ', -1, -1, 'ChangeUserType')
    END
END



-- --------------UPDATE PIRCE PER DAY FOR A BIKE--------------

CREATE PROCEDURE EditBikePricePerDay @bike_id int, @price_per_day money
    AS
    BEGIN TRY

        IF (not exists (SELECT * FROM Bikes WHERE bike_id = @bike_id AND availability = 'available'))
        BEGIN
            PRINT 'There is not a bike with such an ID.';
            THROW 50004, 'There is not a bike with such an ID.', 1;
        END

        ELSE
        BEGIN
        UPDATE [Bikes] SET [price_per_day] = @price_per_day
        WHERE [Bikes].[bike_id] = @bike_id

            PRINT 'Price per day for this bike has been changed.';
        END

    END TRY


    BEGIN CATCH

        PRINT 'Exception!';
        THROW;

    END CATCH;
    
    
    
-- --------------UPDATE USER--------------

-- -------UPDATE LOGIN-------

CREATE PROCEDURE UpdateUserLogin @user__id int, @login varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET login = @login
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- -------UPDATE PASSWORD-------

CREATE PROCEDURE UpdateUserPassword @user__id int, @user_password varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET user_password = @user_password
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- -------UPDATE NAME-------

CREATE PROCEDURE UpdateUserName @user__id int, @name varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET name = @name
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- -------UPDATE SURNAME-------

CREATE PROCEDURE UpdateUserSurname @user__id int, @surname varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET surname = @surname
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- -------UPDATE NRTEL-------

CREATE PROCEDURE UpdateUserNrTel @user__id int, @nr_tel varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET tel_nr = @tel_nr
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- -------UPDATE EMAIL-------

CREATE PROCEDURE UpdateUserEmail @user__id int, @email varchar(50)
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id AND is_deleted = 0))
    BEGIN
        UPDATE Users
        SET email = @email
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'UpdateUser')
    END
END



-- ----------------------------------------------------------------------------------------------DELETE-------------------------------------------------------------------------------------------------------------

-- --------------DELETE USER--------------

CREATE PROCEDURE DeleteUser @user__id int
AS
BEGIN
    IF (exists (SELECT * FROM Users WHERE user__id = @user__id))
    BEGIN
        UPDATE Users
        SET is_deleted = 1
        WHERE user__id = @user__id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a user. ', -1, -1, 'DeleteUser')
    END
END



-- --------------DELETE BIKE-------------- 

CREATE PROCEDURE DeleteBike @bike_id int
AS
BEGIN
    IF (exists (SELECT * FROM Bikes WHERE bike_id = @bike_id))
    BEGIN
        UPDATE Bikes
        SET availability = 'deleted'
        WHERE bike_id = @bike_id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a bike. ', -1, -1, 'DeleteBike')
    END
END



-- --------------DELETE BASE-------------- 

CREATE PROCEDURE DeleteBase @base_id int
AS
BEGIN
    IF (exists (SELECT * FROM Bases WHERE base_id = @base_id))
    BEGIN
        IF (exists (SELECT * FROM Bikes WHERE base_id = @base_id AND availability = 'available'))
        BEGIN
            RAISERROR ('You cannot delete this base, because there are bikes available. ', -1, -1, 'DeleteBase')
        END
        ELSE
        BEGIN
            UPDATE Bases
			SET is_deleted = 1
            WHERE base_id = @base_id;
        END
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a base. ', -1, -1, 'DeleteBase')
    END
END



-- --------------DELETE SERVICE COMPANY-------------- 

CREATE PROCEDURE DeleteServiceCompany @service_cmp_id int
AS
BEGIN
    IF (exists (SELECT * FROM Service_companies WHERE service_cmp_id = @service_cmp_id))
    BEGIN
        IF (not exists (SELECT * FROM Servicemen WHERE service_cmp_id = @service_cmp_id))
        BEGIN
            UPDATE Service_companies
			SET is_deleted = 1
            WHERE service_cmp_id = @service_cmp_id;
        END
        ELSE
        BEGIN
            RAISERROR ('There are still servicemen assigned to this company. ', -1, -1, 'DeleteServiceCompany')
        END
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a company. ', -1, -1, 'DeleteServiceCompany')
    END
END



-- --------------DELETE SERVICEMAN-------------- 

CREATE PROCEDURE DeleteServiceman @serviceman_id int
AS
BEGIN
    IF (exists (SELECT * FROM Servicemen WHERE serviceman_id = @serviceman_id))
    BEGIN
        UPDATE Servicemen
        SET is_deleted = 1
        WHERE serviceman_id = @serviceman_id;
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a serviceman. ', -1, -1, 'DeleteServiceman')
    END
END




-- ----------------------------------------------------------------------------------------------OTHER-----------------------------------------------------------------------------------------------------------

-- --------------BIKES FOR CURRENT BASE-------------- 

CREATE PROCEDURE ShowBikesForCurrentBase @base_id int
AS
BEGIN
    IF (exists (SELECT * FROM Bases WHERE base_id = @base_id AND is_deleted = 0))
    BEGIN
        IF(exists (SELECT bike_id FROM Bases WHERE base_id = @base_id AND availability = 'available'))
        BEGIN
            SELECT bike_id FROM Bases WHERE base_id = @base_id;    
        END
        ELSE
        BEGIN
            RAISERROR ('There are not any bikes in that base. ', -1, -1, 'ShowBikesForCurrentBase')
        END
    END
    ELSE
    BEGIN
        RAISERROR ('There is no such a base. ', -1, -1, 'ShowBikesForCurrentBase')
    END
END




-- =============================================================================================VIEWS=======================================================================================================

        
CREATE VIEW [Rentals_raport] AS
SELECT dbo.Bikes.bike_id, dbo.Bikes.price_per_day, dbo.Rentals.rental_id, dbo.Rentals.start_date, dbo.Rentals.finish_date, dbo.Rentals.charge
FROM dbo.Bikes INNER JOIN dbo.Rentals ON dbo.Bikes.bike_id = dbo.Rentals.bike_id

GO

CREATE VIEW [Rentals_marketing_report] AS
SELECT dbo.Users.user__id, dbo.Rentals.start_date, dbo.Rentals.finish_date, dbo.Rentals.charge, dbo.Rentals.bike_id, dbo.Rentals.user__id AS Expr1, dbo.Users.name, dbo.Users.surname, dbo.Users.tel_nr, dbo.Users.email
FROM dbo.Users INNER JOIN dbo.Rentals ON dbo.Users.user__id = dbo.Rentals.user__id AND dbo.Users.user_type_id = 1

GO

CREATE VIEW [Bike_income_per_month] AS
SELECT bike_id, SUM(charge) AS Income, MONTH(finish_date) AS Month
FROM Rentals
WHERE YEAR(finish_date) = YEAR(GETDATE())
GROUP BY MONTH(finish_date), bike_id

GO

CREATE VIEW [Bike_income_per_year] AS
SELECT bike_id, SUM(charge) AS Income, YEAR(finish_date) AS Year
FROM Rentals
GROUP BY YEAR(finish_date), bike_id
        
GO
        
CREATE VIEW [Bikes_per_base] AS
SELECT dbo.Bikes.bike_id AS bike_id, dbo.Bikes.price_per_day, dbo.Bases.address
FROM Bikes INNER JOIN Bases ON Bikes.bike_id = Bases.base_id
WHERE Bikes.availability = 'available'
    
    
--=============================================================================================ROLES=======================================================================================================
        
        
CREATE ROLE AppUser;

GO

CREATE ROLE Accountant;

GO

CREATE ROLE Marketing_analyst;

GO

CREATE ROLE Marketing_manager;

GO

CREATE ROLE Financial_manager;

GO

CREATE ROLE Staff_manager;

GO

CREATE ROLE Staff;
    
    
    
    
    
    

        
        
        
        
        
        
        
        GRANT SELECT ON Users TO Staff_manager;
GO
GRANT INSERT ON Users TO Staff_manager;
GO
GRANT UPDATE ON Users TO Staff_manager;
GO
GRANT REFERENCES ON Users TO Staff_manager;
GO


GRANT SELECT ON User_type TO Staff_manager;
GO
GRANT INSERT ON User_type TO Staff_manager;
GO
GRANT UPDATE ON User_type TO Staff_manager;
GO
GRANT REFERENCES ON User_type TO Staff_manager
GO


GRANT SELECT ON Bases TO Staff_manager;
GO
GRANT INSERT ON Bases TO Staff_manager;
GO
GRANT UPDATE ON Bases TO Staff_manager;
GO
GRANT REFERENCES ON Bases TO Staff_manager;



GRANT SELECT ON Bikes TO Staff_manager;
GO
GRANT INSERT ON Bikes TO Staff_manager;
GO
GRANT UPDATE ON Bikes TO Staff_manager;
GO
GRANT REFERENCES ON Bikes TO Staff_manager;
GO


GRANT SELECT ON Transport TO Staff_manager;
GO
GRANT INSERT ON Transport TO Staff_manager;
GO
GRANT UPDATE ON Transport TO Staff_manager;
GO
GRANT REFERENCES ON Transport TO Staff_manager;
GO

    
    
    
        
        
GRANT SELECT ON Bikes TO Accountant;
GO
GRANT SELECT ON Users TO Accountant;
GO
GRANT SELECT ON Bases TO Accountant;
GO
GRANT SELECT ON Rentals TO Accountant;
GO
GRANT SELECT ON Service_companies TO Accountant;
GO
GRANT SELECT ON Services TO Accountant;
GO
GRANT SELECT ON Bike_income_per_month TO Accountant;
GO
GRANT SELECT ON Bike_income_per_year TO Accountant;
GO
GRANT SELECT ON Rentals_raport TO Accountant;





