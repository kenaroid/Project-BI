
CREATE DATABASE bi_project;
go

DROP TABLE [game_history];
GO


DROP TABLE [bank];
GO


DROP TABLE [games];
GO


DROP TABLE [transaction_types];
GO


DROP TABLE [players];
GO


--************************************** [games]

CREATE TABLE [games]
(
 [gameId] int NOT NULL , -- dobavil int
 [name]   VARCHAR(100) NOT NULL ,
 [type]   VARCHAR(100) NOT NULL ,

 CONSTRAINT [PK_games] PRIMARY KEY CLUSTERED ([gameId] ASC)
);
GO

--INSERT INTO games(gameId,name, type)  VALUES(1,'Slot Machine','slots');  dobavil edinizy , zachem sdelali insert ?

--************************************** [transaction_types]

CREATE TABLE [transaction_types]
(
 [typeId]  int   NOT NULL ,  -- dobavil int
 [name]      VARCHAR(50) NOT NULL ,
 [direction] TINYINT NOT NULL CHECK (direction IN(1, -1))

 CONSTRAINT [PK_transaction_types] PRIMARY KEY CLUSTERED ([typeId] ASC)
);
GO

INSERT INTO transaction_types(name, direction)  VALUES('Deposit',1); --zachem sdelali insert ?
INSERT INTO transaction_types(name, direction)  VALUES('Cashout',-1);
INSERT INTO transaction_types(name, direction)  VALUES('Win',1);
INSERT INTO transaction_types(name, direction)  VALUES('Loos',-1);
INSERT INTO transaction_types(name, direction)  VALUES('Bonus',1);


--************************************** [players]

CREATE TABLE [players]
(
 [userID]    INT NOT NULL ,-- ?
 [password]  VARCHAR(50) NOT NULL ,
 [firstName] VARCHAR(100) NOT NULL ,
 [lastName]  VARCHAR(150) NOT NULL ,
 [address]   TEXT NOT NULL ,
 [country]   VARCHAR(150) NOT NULL ,
 [email]     VARCHAR(150) NOT NULL ,
 [gender]    VARCHAR(10) NOT NULL ,
 [birthDate] DATE NOT NULL ,
 [userName]  UNIQUEIDENTIFIER NOT NULL ,

 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([userID] ASC) ---  PK_users ????
);
GO



--************************************** [bank]

CREATE TABLE [bank]
(
 [transactionID]   INT NOT NULL ,
 [amount]          FLOAT NOT NULL ,
 [typeId]          int   NOT NULL , -- dobavil int
 [transactionTime] DATETIME NOT NULL ,
 [bankAmount]      FLOAT NOT NULL ,
 [userID]          INT NOT NULL ,

 CONSTRAINT [PK_bank] PRIMARY KEY CLUSTERED ([transactionID] ASC),
 CONSTRAINT [FK_33] FOREIGN KEY ([typeId])
  REFERENCES [transaction_types]([typeId]),
 CONSTRAINT [FK_39] FOREIGN KEY ([userID])
  REFERENCES [players]([userID])
);
GO


--SKIP Index: [fkIdx_33]

--SKIP Index: [fkIdx_39]


--************************************** [game_history]

CREATE TABLE [game_history]
(
 [roundId]       INT NOT NULL ,
 [bet]           FLOAT NOT NULL ,
 [isWin]         BIT NOT NULL ,
 [roundTime]     DATETIME NOT NULL ,
 [gameId]        int      NOT NULL ,
 [transactionID] INT NOT NULL ,

 CONSTRAINT [PK_game_history] PRIMARY KEY CLUSTERED ([roundId] ASC),
 CONSTRAINT [FK_68] FOREIGN KEY ([gameId])
  REFERENCES [games]([gameId]),
 CONSTRAINT [FK_80] FOREIGN KEY ([transactionID])
  REFERENCES [bank]([transactionID])
);
GO

--------------------------------------------------------------------

use bi_project

---register
go

CREATE PROCEDURE dbo.player_register  @username nchar (10)
                                      @password nchar (10)
		                              @firstName  nchar (10)
		                              @lastName   nchar (10)
		                              @adress   nchar (10)
		                              @country  char  (20)
		                              @email    nchar (10)
		                              @gender   char  (10)
		                              @birth_date date 

begin 

  if  @username not in (select username from players ) 
    insert into players	(username,password,firstName,lastName,address,country,email,gender,birthDate)   ---- userID ???  
    values (@username, @password, @firstName, @lastName, @adress, @country, @email, @gender, @bisht, @birthDate  )
else print 'username exist'

   @username +''+ Cast(RAND()*(50-1)+1 as int) --- alternative username

  --- chek password 

  len(@password)>= 5
   
  SUBSTRING(@password,1,1) != LOWER(SUBSTRING(@password,1,1))    -----   https://blog.sqlauthority.com/2007/04/30/case-sensitive-sql-query-search/
   
--------------------------------------------------Upper Case in password-------
   DECLARE
   @TestString VARCHAR(100)

SET @TestString = 'ggg'

SELECT CASE WHEN BINARY_CHECKSUM(@TestString) = BINARY_CHECKSUM(LOWER(@TestString)) THEN 0 ELSE 1 END AS DoesContainUpperCase
GO

-------------------------------------lower Case in password---------------------------

 DECLARE
  @password VARCHAR(100)

SET @password = 'TTTT'

SELECT CASE WHEN BINARY_CHECKSUM(@password) = BINARY_CHECKSUM(UPPER(@password)) THEN 0 ELSE 1 END AS DoesContainLowerCase
GO
  
----------------------number in string--------------------

PATINDEX('%[0-9]%', @password)


--------------------------
 @username!=@password

 @password!= 'password'  --- chek small and capital letters ?

 ------------legal email adress format--------------------------

 https://en.wikipedia.org/wiki/Email_address

--------------------------------login------------------------------------

go;

CREATE PROCEDURE dbo.player_login     @username nchar (10)
                                      @password nchar (10)
									  @count    int
declare  @count   int

SET @count=0
WHILE @count < 6

BEGIN
   PRINT 'Please insert password';
   SET @count = @count + 1;

       if @password= password;
	    exit;
       else print 'Please insert CORRECT password';
	   @count = @count + 1;


end dbo.player_login;

GO
