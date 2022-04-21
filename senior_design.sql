CREATE DATABASE ‘derby_dash’;
CREATE TABLE `derby_dash`.`runs` (
`id` INT NOT NULL , `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP , 
`track` INT NULL DEFAULT NULL , `sensor_2` INT NULL DEFAULT NULL 
`sensor_3` INT NULL DEFAULT NULL , 
`total_time` DECIMAL((4,2)) NULL DEFAULT NULL ) 
ENGINE = InnoDB;

CREATE TABLE `derby_dash`.`daily` (
`run_date` DATE NOT NULL DEFAULT CURRENT_TIMESTAMP , 
`max_time` DECIMAL((4,2)) NULL DEFAULT NULL , 
`min_time` DECIMAL((4,2)) NULL DEFAULT NULL , 
`run_success` INT NULL DEFAULT NULL , 
`run_unsuccess` INT NULL DEFAULT NULL , 
`total_run` INT NULL DEFAULT NULL ) 
ENGINE = InnoDB;

CREATE TABLE `derby_dash`.`monthly` (
`month_val` INT NOT NULL , `year_val` INT NOT NULL ,
`max_time` DECIMAL((4,2)) NOT NULL , 
`min_time` DECIMAL((4,2)) NOT NULL , 
`run_success` INT NOT NULL , `run_unsuccess` INT NOT NULL , 
`total_run` INT NOT NULL ) 
ENGINE = InnoDB;

CREATE PROCEDURE `daily_procedure`() NOT DETERMINISTIC NO SQL SQL SECURITY DEFINER 
BEGIN
INSERT INTO daily(max_time, min_time, run_success, run_unsuccess, total_run) 
SELECT (SELECT MAX(CASE WHEN sensor_3>0 
  		then total_time 
 		else 0.0 END)) as max_time, 
            
(SELECT MIN(CASE WHEN sensor_3>0
then total_time 
else 20 END)) as min_time, 
             
SUM(CASE WHEN sensor_3=1 
THEN 1 
ELSE 0 END) as run_success, 
                
SUM(CASE WHEN sensor_3=0 
THEN 1 
 ELSE 0 END) as run_unsuccess, 
                     
COUNT(sensor_2) as total_run
    	FROM runs
   	WHERE date(timestamp) = CURRENT_DATE;
END;

CREATE PROCEDURE `monthly_procedure`() NOT DETERMINISTIC NO SQL SQL SECURITY DEFINER 
BEGIN 
IF CURRENT_DATE=last_day(curdate()) 
THEN 
INSERT INTO monthly(month_val, year_val, max_time, min_time, run_success, run_unsuccess, 	total_run) 
SELECT 
EXTRACT(MONTH FROM run_date) as month_val,
EXTRACT(YEAR FROM run_date) as year_val, 
MAX(max_time) as max_time, 
MIN(min_time) as min_time, 
SUM(run_success) as run_success, 
SUM(run_unsuccess) as run_unsuccess, 
SUM(total_run) as total_run 
FROM daily 
WHERE MONTH(CURRENT_DATE) > MONTH(CURRENT_DATE)-1; 
END IF; 
END;

CREATE PROCEDURE `fakedata`() NOT DETERMINISTIC NO SQL SQL SECURITY DEFINER 
BEGIN 
INSERT INTO runs(acceleration, track, sensor_2, sensor_3, total_time) 
SELECT  
ROUND(RAND())+1 as track, 
ROUND(RAND()) as sensor_2, 
ROUND(RAND()) as sensor_3, 
(RAND()*(7-4+1))+4 as total_time; 
END;
CREATE EVENT `daily_update` 
ON SCHEDULE 
EVERY 1 DAY 
STARTS '2022-03-31 00:16:00.000000' 
ON COMPLETION NOT PRESERVE ENABLE 
DO 
CALL daily_procedure();

CREATE EVENT `monthly_update` 
ON SCHEDULE 
EVERY 1 DAY 
STARTS '2022-03-25 00:16:55.000000' 
ON COMPLETION NOT PRESERVE ENABLE 
DO 
CALL monthly_procedure();
CREATE EVENT `fakedata_input` 
	ON SCHEDULE 
EVERY 2 HOUR 
STARTS '2022-03-29 00:14:00.000000' 
ON COMPLETION NOT PRESERVE ENABLE 
DO 
CALL fakedata();

