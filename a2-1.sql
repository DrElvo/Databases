-- Answer to the 2nd Database Assignment Part 1 
-- Term 1, 2022
--
-- CANDIDATE NUMBER: 232560
-- Please insert your candidate number in the line above - you should replace xxxxxx with your candidate number.


-- In each section below put your answer in a new line 
-- BELOW the corresponding comment.
-- Use ONE SQL statement ONLY per question.
-- If you don’t answer a question just leave the corresponding space blank. 
-- Anything that does not run in SQL you MUST put in comments.

-- DO NOT REMOVE ANY LINE FROM THIS FILE.

-- START OF ASSIGNMENT CODE


-- @@1

CREATE TABLE MoSpo_HallOfFame(
	hoFdriverId INT unsigned, 
	hoFYear YEAR, 
	hoFSeries ENUM('BritishGT', 'Formula1', 'FormulaE', 'SuperGT') NOT NULL,
	hoFImage VARCHAR(200),
	hoFWins TINYINT(99) UNSIGNED DEFAULT 0, 
	hoFBestRaceName VARCHAR(30), 
	hoFBestRaceDate DATE, 
	CONSTRAINT PK_HallOfFame PRIMARY KEY (hoFdriverId, hoFYear), 
	CONSTRAINT FK_DriveID FOREIGN KEY (hoFdriverId) REFERENCES MoSpo_Driver(driverId),
	CONSTRAINT FK_BESTNAME_DATE FOREIGN KEY (hoFBestRaceName, hoFBestRaceDate) REFERENCES MoSpo_Race(raceName, raceDate) ON DELETE SET NULL

);
 
-- @@2

ALTER TABLE MoSpo_Driver
ADD COLUMN driverWeight FLOAT CHECK(driverWeight >= 0.0 AND driverWeight <= 99.9);

-- @@3

UPDATE MoSpo_RacingTeam SET teamPostcode = 'HP135PN' WHERE teamName = 'Beechdean Motorsport' ;

-- @@4

DELETE FROM MoSpo_Driver WHERE driverLastname LIKE 'Senna'  AND driverFirstname LIKE 'Ayrton' ;

-- @@5

SELECT COUNT(*) AS numberTeams FROM MoSpo_RacingTeam;

-- @@6

SELECT driverId, CONCAT(LEFT(driverFirstName, 1), ' ', driverLastName) AS driverName, driverDOB FROM MoSpo_Driver
WHERE LEFT(driverFirstName, 1) = LEFT(driverLastName, 1)


-- @@7

SELECT Teams.teamName AS teamName, COUNT(Driver.driverId) AS numberOfDriver

FROM MoSpo_Driver Driver INNER JOIN MoSpo_RacingTeam Teams  ON  Driver.driverTeam = Teams.teamName

GROUP BY Teams.teamName HAVING COUNT(Driver.driverId) > 1;

-- @@8

SELECT raceName, raceDate, MIN(Lap.lapInfoTime) lapTime 

FROM MoSpo_Race Race INNER JOIN MoSpo_LapInfo Lap  ON  (Race.raceName,Race.raceDate) = (Lap.lapInfoRaceName,Lap.lapInfoRaceDate) 

WHERE Lap.lapInfoTime IS NOT NULL

GROUP BY raceName,raceDate;

-- @@9

SELECT pitstopRaceName AS pitstopRaceName, 
COUNT( pitstopRaceName)/COUNT(DISTINCT pitstopRaceDate) AS pitstopAverage 
FROM MoSpo_PitStop GROUP BY pitstopRaceName;

-- @@10

SELECT Distinct Cr.carMake FROM MoSpo_RaceEntry AS Rc_En 
JOIN MoSpo_Car AS Cr ON Rc_En.raceEntryCarId = Cr.carId 
JOIN MoSpo_LapInfo AS Lp_In ON (Lp_In.lapInfoRaceName,Lp_In.lapInfoRaceDate) = (Rc_En.raceEntryRaceName,Rc_En.raceEntryRaceDate)
WHERE Lp_In.lapInfoCompleted = 0 AND Rc_En.raceEntryRaceDate BETWEEN '2018-01-01' AND '2018-12-31';

-- @@11

SELECT raceName, raceDate, MAX(Pitstops) AS mostPitStops  

FROM (SELECT Rc_In.raceName, Rc_In.raceDate, COUNT(Pt_Sp_In.pitstopRaceNumber) AS Pitstops

FROM MoSpo_Race Rc_In LEFT JOIN MoSpo_PitStop Pt_Sp_In ON (Rc_In.raceName,Rc_In.raceDate) = (Pt_Sp_In.pitstopRaceName,Pt_Sp_In.pitstopRaceDate)

GROUP BY raceName, raceDate, pitstopRaceNumber) AS InnerStop

GROUP BY raceName, raceDate;

-- @@12

DELIMITER $$

CREATE FUNCTION totalRaceTime(raceName VARCHAR(255), raceDate DATE, racingNumber INT)
RETURNS INT

BEGIN
DECLARE TimeRaced INT; 
DECLARE TotalLaps INT;
DECLARE FullLaps INT;
DECLARE NonFullLaps INT;

SELECT COUNT(lapNo)
INTO TotalLaps
FROM MoSpo_Lap
WHERE lapRaceName = raceName
AND lapRaceDate = raceDate;

SELECT SUM(lapInfoTime)
INTO TimeRaced
FROM MoSpo_LapInfo
WHERE lapInfoRaceName = raceName
AND lapInfoRaceDate = raceDate
AND lapInfoRaceNumber = racingNumber;

SELECT COUNT(lapInfoLapNo)
INTO FullLaps
FROM MoSpo_LapInfo
WHERE lapInfoRaceName = raceName
AND lapInfoRaceDate = raceDate
AND lapInfoRaceNumber = racingNumber
AND lapInfoCompleted = 1;

IF TotalLaps = 0 THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RACE NOT FOUND';
END IF;

IF FullLaps = 0 THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RACING NUMBER NOT FOUND';
END IF;

IF TotalLaps != FullLaps THEN
	SELECT NULL INTO TimeRaced;
ELSE
	SELECT COUNT(lapInfoLapNo)
	INTO NonFullLaps
	FROM MoSpo_LapInfo
	WHERE lapInfoRaceName = raceName 
	AND lapInfoRaceDate = raceDate 
	AND lapInfoRaceNumber = racingNumber 
	AND lapInfoTime IS NULL;
	IF NonFullLaps > 0 AND TotalLaps = FullLaps THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'REQUIRED LAPS NOT MET'; 
	END IF;
END IF;
RETURN TimeRaced;
END$$


