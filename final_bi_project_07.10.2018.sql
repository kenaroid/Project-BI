CREATE DATABASE bi_project COLLATE SQL_Latin1_General_CP1_CS_AS;

CREATE TABLE [games]
(
 [gameId] INT IDENTITY(1,1) PRIMARY KEY,
 [name]   VARCHAR(100) NOT NULL ,
 [type]   VARCHAR(100) NOT NULL 
);
GO

INSERT INTO games(name, type)  VALUES('Slot Machine','slots'); 

select * from games

CREATE TABLE [transaction_types]
(
 [typeId]  INT IDENTITY(1,1) PRIMARY KEY,
 [name]   VARCHAR(50) NOT NULL ,
 [direction] SMALLINT NOT NULL CHECK (direction IN(1, -1))
);
GO

INSERT INTO transaction_types( name, direction)  VALUES('Deposit',1);
INSERT INTO transaction_types( name, direction)  VALUES('Cashout',-1);
INSERT INTO transaction_types( name, direction)  VALUES('Win',1);
INSERT INTO transaction_types( name, direction)  VALUES('Loos',-1);
INSERT INTO transaction_types( name, direction)  VALUES('Bonus',1);

select * from  [transaction_types]

CREATE TABLE [players]
(
 [userID]    INT IDENTITY(1,1) PRIMARY KEY,
 [userName]  VARCHAR(100)  NOT NULL UNIQUE,
 [psswrd]  VARCHAR(50) NOT NULL ,
 [firstName] VARCHAR(100) NOT NULL ,
 [lastName]  VARCHAR(150) NOT NULL ,
 [address]   TEXT NOT NULL ,
 [country]   VARCHAR(150) NOT NULL ,
 [email]     VARCHAR(150) NOT NULL ,
 [gender]    VARCHAR(10) NOT NULL ,
 [birthDate] DATE NOT NULL,
 [isLoggedIn] TINYINT NOT NULL default 0,
 [loginAttempts] INT NOT NULL default 0
);

CREATE TABLE [bank]
(
 [transactionID]   INT IDENTITY(1,1) PRIMARY KEY,
 [amount]          FLOAT NOT NULL ,  --- amount of transaction
 [typeId]          INT NOT NULL ,
 [transactionTime] DATETIME NOT NULL ,
 [bankAmount]      FLOAT NOT NULL ,
 [userID]          INT NOT NULL ,

 CONSTRAINT [FK_33] FOREIGN KEY ([typeId])
  REFERENCES [transaction_types]([typeId]),
 CONSTRAINT [FK_39] FOREIGN KEY ([userID])
  REFERENCES [players]([userID])
);

CREATE TABLE [game_history]
(
 [roundId]       INT IDENTITY(1,1) PRIMARY KEY,
 [isWin]         BIT NOT NULL ,  -- smallest column type , can be only 1 or 0
 [roundTime]     DATETIME NOT NULL ,
 [gameId]        int      NOT NULL ,
 [transactionID] INT NOT NULL ,

 CONSTRAINT [FK_68] FOREIGN KEY ([gameId])
  REFERENCES [games]([gameId]),
 CONSTRAINT [FK_80] FOREIGN KEY ([transactionID])
  REFERENCES [bank]([transactionID])
);

go
--************************************ PROCEDURE player_login
CREATE PROCEDURE dbo.player_login
     @username VARCHAR(100),
     @psswrd  VARCHAR(50)
AS
BEGIN
SET NOCOUNT ON

DECLARE  
  @isLoggedIn as BIT,
  @userID as INT,
  @loginAttempts as INT

SELECT @isLoggedIn = isLoggedIn, @userID=userID FROM [players] WHERE userName = @username AND psswrd = @psswrd AND loginAttempts < 6

IF( @@ROWCOUNT < 1 ) 
 	BEGIN
 		SELECT @loginAttempts=loginAttempts FROM [players] WHERE userName = @username
		UPDATE [players] SET loginAttempts = loginAttempts + 1 WHERE userName = @username; 
		SELECT 'Login Failed. You have ' + Cast( (4 - @loginAttempts) as varchar)  + ' attempts left'
  END
ELSE
 	BEGIN
 		IF( @isLoggedIn > 0 )
				SELECT 'User Already Logged In' 
		ELSE
      BEGIN
		    UPDATE [players] SET isLoggedIn = 1, loginAttempts = 0 WHERE userID=@userID; 
    		SELECT 'Login Successful' 
    	END
	END
END

go;
--************************************ PROCEDURE player_register
CREATE PROCEDURE dbo.player_register_1 @username VARCHAR(100),
                                       @psswrd  VARCHAR(50),
									   @firstName VARCHAR(100),
									   @lastName  VARCHAR(150),
									   @address   TEXT,
									   @country   VARCHAR(150),
									   @email     VARCHAR(150),
									   @gender    VARCHAR(10),
									   @birthDate DATE
AS
BEGIN
SET NOCOUNT ON

DECLARE  
  @userID as BIGINT,
  @transaction_typeId as INT

IF DATEDIFF ( year , @birthDate, getdate()) < 18
	SELECT 'ERROR: user nmust be over 18 years old'
ELSE 
  BEGIN
		IF @psswrd <> @username
			AND @psswrd NOT LIKE '[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]%'
			AND @psswrd like '%[0-9]%' 
			AND @psswrd LIKE '%[A-Z]%' 
			AND @psswrd LIKE '%[a-z]%' 
			AND DATALENGTH(@psswrd) >= 5
			BEGIN
				IF EXISTS (SELECT * FROM [players] WHERE userName = @username)
					BEGIN
		    		SELECT 'ERROR: user name exist. Please try other, for example : ' +  @username + Cast( Cast(RAND()*(50-1)+1 as int) as varchar) 
					END
				ELSE
					BEGIN
					    INSERT INTO [players]	(
							    [userName],
							    [psswrd],
							    [firstName],
							    [lastName],
							    [address],
							    [country],
							    [email],
							    [gender],
							    [birthDate]) 
						    VALUES (
									@username,
									@psswrd,
									@firstName,
									@lastName,
									@address,
									@country,
									@email,
									@gender,
									@birthDate );
									
							SET @userID = SCOPE_IDENTITY();
							
							SELECT @transaction_typeId=typeId FROM [transaction_types] WHERE name='Bonus';
							
					    INSERT INTO [bank]	(
									[amount],
									[typeId],
									[transactionTime],
									[bankAmount],
									[userID]) 
								values (
									10,
									@transaction_typeId,
									GETDATE(),
									10,
									@userID
		);
							
					    SELECT 'User ' +  @username  + ' with ID: ' + Cast( @userID as varchar)  + ' was successfully created. You got bonus USD 10!'
					END
			END -- end of password check
		ELSE
		  SELECT 'ERROR: bad password. Password must contain numbers, ....' 
		END
	END  -- end of age check

go;
--************************************ PROCEDURE get_player_current_bankroll
CREATE PROCEDURE dbo.get_player_current_bankroll @username VARCHAR(100)
AS
BEGIN
SET NOCOUNT ON

DECLARE @bankAmountBefore INT
 
SELECT @bankAmountBefore=bankAmount 
    FROM [dbo].[bank] b 
    INNER JOIN [dbo].[players] p 
        ON b.userID = p.userID 
    WHERE p.userName = @username ;

SELECT 'You have ' + Cast( @bankAmountBefore as varchar) + ' on your account.';
 
END

go

--************************************ PROCEDURE play_game_turn
CREATE PROCEDURE dbo.play_game_turn @bet        INT,
                                    @gameId     INT,
                                    @username VARCHAR(100)
		
AS
BEGIN
SET NOCOUNT ON

DECLARE
 @startGame DATETIME,
 @currentBankroll INT,
 @newBankroll INT,
 @userID   INT,
 @typeId   INT,
 @transactionID  INT,
 @wheeel1  INT,
 @wheeel2  INT,
 @wheeel3  INT
 
SELECT @currentBankroll=b.bankAmount, @userID=p.userID 
    FROM [dbo].[bank] b 
    INNER JOIN [dbo].[players] p 
        ON b.userID=p.userID 
    WHERE p.userName = @username

IF (@bet <= @currentBankroll)
    BEGIN
	    SET @startGame= GETDATE()
 	    SET @wheeel1 = (SELECT ABS(CHECKSUM(NEWID()) % 6) + 1)
 	    SET @wheeel2 = (SELECT ABS(CHECKSUM(NEWID()) % 6) + 1)
	    SET @wheeel3 = (SELECT ABS(CHECKSUM(NEWID()) % 6) + 1)
	    
		IF ( @wheeel1 = @wheeel2 AND @wheeel2=@wheeel3 ) 
			BEGIN --Win
				SELECT @typeId=typeId FROM [transaction_types] WHERE name='Win';
	            SET @newBankroll= @bet + @currentBankroll
				
				INSERT INTO [bank] (
															[amount],
															[typeId],
															[transactionTime],
															[bankAmount],
															[userID]
								 						)
								 		VALUES (
															@bet,
															@typeId,
															@startGame,
															@newBankroll,
															@userID
								 						);				 		
				 SET @transactionID = SCOPE_IDENTITY(); -- get Id of last inserted row
				 
				 INSERT INTO [game_history] (
																			[isWin],
																			[roundTime],
																			[gameId],
																			[transactionID]
								 						)
								 		VALUES (
												 		1,
														@startGame,
												 		@gameId,
												 		@transactionID
								 						);
					SELECT 'Congratulations! You Won!'			 						
			END
		ELSE --if not win
					BEGIN --Win
						SELECT @typeId=typeId FROM [transaction_types] WHERE name='Loos';
						SET @newBankroll= @currentBankroll - @bet
						
						INSERT INTO [bank] (
																	[amount],
																	[typeId],
																	[transactionTime],
																	[bankAmount],
																	[userID]
										 						)
										 		VALUES (
																	@bet,
																	@typeId,
																	@startGame,
																	@newBankroll,
																	@userID
										 						);				 		
						 SET @transactionID = SCOPE_IDENTITY(); -- get Id of last inserted row
						 
						 INSERT INTO [game_history] (
																					[isWin],
																					[roundTime],
																					[gameId],
																					[transactionID]
										 						)
										 		VALUES (
														 		0,
																@startGame,
														 		@gameId,
														 		@transactionID
										 						);
							SELECT 'Sorry! you lose!'	 						
					END
		END
ELSE -- wrong bet
    BEGIN
		  SELECT 'ERROR: bet ammout must be smaller or equal than your current bankroll : ' + Cast( @currentBankroll as varchar)
    END
END

go
--************************************ PROCEDURE player_cashout
CREATE PROCEDURE dbo.player_cashout @username VARCHAR(100), @amount INT  
											  
AS
BEGIN
SET NOCOUNT ON

DECLARE @bankAmountBefore INT, 
				@bankAmountAfter INT,
				@transaction_typeId INT,
				@userID INT,
				@transaction_time DATETIME
 
 
SELECT @bankAmountBefore=b.bankAmount, @userID=p.userID 
    FROM [dbo].[bank] b 
    INNER JOIN [dbo].[players] p 
        ON b.userID=p.userID 
    WHERE p.userName = @username

IF (@amount > @bankAmountBefore)
	BEGIN
		SELECT 'ERROR: cashout ammout must be smaller or equal than your current bankroll : ' + Cast( @bankAmountBefore as varchar)
	END
ELSE
	BEGIN
		SET @transaction_time= GETDATE()
		SELECT @transaction_typeId=typeId FROM [transaction_types] WHERE name = 'Cashout';
		SET @bankAmountAfter = @bankAmountBefore - @amount
		
		INSERT INTO [bank] (
											[amount],
											[typeId],
											[transactionTime],
											[bankAmount],
											[userID]
				 						)
				 		VALUES (
											@amount,
											@transaction_typeId,
											@transaction_time,
											@bankAmountAfter,
											@userID
				 						);		
		SELECT 'You have ' + Cast( @bankAmountAfter as varchar) + ' on your account now.';
	END
END

go
--************************************ PROCEDURE player_deposit
CREATE PROCEDURE dbo.player_deposit @username VARCHAR(100), @amount INT  
											  
AS
BEGIN
SET NOCOUNT ON

DECLARE @bankAmountBefore INT, 
				@bankAmountAfter INT,
				@transaction_typeId INT,
				@userID INT,
				@transaction_time DATETIME
 
 
SELECT @bankAmountBefore=b.bankAmount, @userID=p.userID 
    FROM [dbo].[bank] b 
    INNER JOIN [dbo].[players] p 
        ON b.userID=p.userID 
    WHERE p.userName = @userName
	
BEGIN
		SET @transaction_time = GETDATE()
		SELECT @transaction_typeId=typeId FROM [transaction_types] WHERE name = 'Deposit';
		SET @bankAmountAfter = @bankAmountBefore + @amount
		
		INSERT INTO [bank] (
											[amount],
											[typeId],
											[transactionTime],
											[bankAmount],
											[userID]
				 						)
				 		VALUES (
											@amount,
											@transaction_typeId,
											@transaction_time,
											@bankAmountAfter, -- !!!!  [bankAmount] = @bankAmountAfter
											@userID
				 						);		
		SELECT 'You have ' + Cast( @bankAmountAfter as varchar) + ' on your account now.';
	END
END	
	
go	
-- REPORTS : --	
	
--***************************************
-- drop function dbo.game_history_report
CREATE FUNCTION dbo.game_history_report (@userID INT, @GameType INT, @StartDateTime DATETIME, @EndDateTime DATETIME)
RETURNS TABLE
AS
RETURN

SELECT 
	g.[gameId] as [Game Id], 
	g.[name] as [Game Name], 
	h.[roundId] as [Round Number],
	b.[amount]as [Bet Amount],
	h.[isWin] as [Win],
	h.[roundTime] as [Round Time]
FROM dbo.[game_history] h 
INNER JOIN dbo.[games] g ON h.gameId = g.gameId 
INNER JOIN dbo.[bank] b ON h.transactionID = b.transactionID 
WHERE
	h.[roundTime] BETWEEN @StartDateTime AND @EndDateTime 
  AND b.userID = @userID
  AND g.[type] = @GameType

-- SELECT * FROM dbo.game_history_report (3, 1,'2018-09-22 00:00:00', '2018-09-29 00:00:00' ) as res ORDER BY res.[Round Time] DESC
-- --***************************************
go
--***************************************
-- drop function dbo.bankroll_transactions_report
CREATE FUNCTION dbo.bankroll_transactions_report (@userID INT, @StartDateTime DATETIME, @EndDateTime DATETIME)
RETURNS TABLE
AS
RETURN

SELECT b.[transactionID] as [Transaction Number], 
       tt.[name] as [Transaction Type],
       b.[transactionTime] as [Transaction Time],
       b.[amount] as [Transaction Amount],
       b.[bankAmount] as [BankRoll  Amount]
FROM [bank] b, [game_history] h
INNER JOIN [transaction_types] tt ON b.typeId = tt.typeId 
WHERE
h.[roundTime] BETWEEN @StartDateTime AND @EndDateTime 
 AND b.userID = @userID
  
  
-- SELECT * FROM dbo.bankroll_transactions_report (3,'2018-09-22 00:00:00', '2018-09-29 00:00:00' ) as res ORDER BY res.[Transaction Time] DESC
-- --***************************************
go;
--***************************************
-- drop function dbo.game_statistics_report
CREATE FUNCTION dbo.game_statistics_report()
RETURNS TABLE
AS
RETURN

SELECT  
	g.[type] as [Game Type], 
	DATEADD(dd, DATEDIFF(dd, 0, h.[roundTime]),0) as [Date],
	COUNT(h.[roundId]) as [Number of Rounds],
	SUM(CAST(h.[isWin] AS INT)) as [Number of Winnigs],
	SUM(b.[amount]) as [Total Bet Amount],
	SUM(b.[amount] * CAST(h.[isWin] AS INT)) as [Total Win Amount]
FROM dbo.[game_history] h 
INNER JOIN dbo.[games] g ON h.gameId = g.gameId 
INNER JOIN dbo.[bank] b ON h.transactionID = b.transactionID 
WHERE
	h.[roundTime] >= DATEADD(day,-7, GETDATE())
GROUP BY 
g.[type],
DATEADD(dd, DATEDIFF(dd, 0, h.[roundTime]),0) 

-- SELECT * FROM dbo.game_statistics_report() as res ORDER BY res.[Game Type] ASC, res.[Date] DESC
-- --***************************************