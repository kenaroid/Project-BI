-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

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
 [gameId]  NOT NULL ,
 [name]   VARCHAR(100) NOT NULL ,
 [type]   VARCHAR(100) NOT NULL ,

 CONSTRAINT [PK_games] PRIMARY KEY CLUSTERED ([gameId] ASC)
);
GO

INSERT INTO games(name, type)  VALUES('Slot Machine','slots');

--************************************** [transaction_types]

CREATE TABLE [transaction_types]
(
 [typeId]     NOT NULL ,
 [name]      VARCHAR(50) NOT NULL ,
 [direction] TINYINT NOT NULL CHECK (direction IN(1, -1))

 CONSTRAINT [PK_transaction_types] PRIMARY KEY CLUSTERED ([typeId] ASC)
);
GO

INSERT INTO transaction_types(name, direction)  VALUES('Deposit',1);
INSERT INTO transaction_types(name, direction)  VALUES('Cashout',-1);
INSERT INTO transaction_types(name, direction)  VALUES('Win',1);
INSERT INTO transaction_types(name, direction)  VALUES('Loos',-1);
INSERT INTO transaction_types(name, direction)  VALUES('Bonus',1);


--************************************** [players]

CREATE TABLE [players]
(
 [userID]    INT NOT NULL ,
 [password]  VARCHAR(50) NOT NULL ,
 [firstName] VARCHAR(100) NOT NULL ,
 [lastName]  VARCHAR(150) NOT NULL ,
 [address]   TEXT NOT NULL ,
 [country]   VARCHAR(150) NOT NULL ,
 [email]     VARCHAR(150) NOT NULL ,
 [gender]    VARCHAR(10) NOT NULL ,
 [birthDate] DATE NOT NULL ,
 [userName]  UNIQUEIDENTIFIER NOT NULL ,

 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([userID] ASC)
);
GO



--************************************** [bank]

CREATE TABLE [bank]
(
 [transactionID]   INT NOT NULL ,
 [amount]          FLOAT NOT NULL ,
 [typeId]           NOT NULL ,
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
 [gameId]         NOT NULL ,
 [transactionID] INT NOT NULL ,

 CONSTRAINT [PK_game_history] PRIMARY KEY CLUSTERED ([roundId] ASC),
 CONSTRAINT [FK_68] FOREIGN KEY ([gameId])
  REFERENCES [games]([gameId]),
 CONSTRAINT [FK_80] FOREIGN KEY ([transactionID])
  REFERENCES [bank]([transactionID])
);
GO


--SKIP Index: [fkIdx_68]

--SKIP Index: [fkIdx_80]


