/*This script is a combined display of how I troubleshooted the same script across different datasets with similar information but not consistent information.
This was my first case study, so I wanted to focus on what problems I encountered and how I solved them.*/

USE cyclistic;
CREATE TABLE `2016_Q1`
(trip_id TEXT, starttime TEXT, stoptime TEXT, bikeid TEXT, tripduration TEXT,
from_station_id TEXT, from_station_name TEXT, to_station_id TEXT, to_station_name TEXT,
usertype TEXT, gender TEXT, birthyear TEXT);

-- 2016 was the only table that had a different column name than the others. Unfortunately, I didn't discover this until after I had already cleaned 2016.
-- All the remaining years have a different name for start/end dates/times. It took a lot of back and forth to get to a level playing field.
USE cyclistic;
CREATE TABLE `2017_Q1`
(trip_id TEXT, start_time TEXT, end_time TEXT, bikeid TEXT, tripduration TEXT,
from_station_id TEXT, from_station_name TEXT, to_station_id TEXT, to_station_name TEXT,
usertype TEXT, gender TEXT, birthyear TEXT);

/*I struggled to add the file because I had it saved in an inaccessible folder. I used this code
to ensure access to be capable of being imported. This worked faster than the import wizard. However, it came with its own complications.
I needed to know the file Workbench had access to and then needed to shift all the datasets I planned to use to that folder.
In the future, I would have to repeat this process as needed to ensure the smoothest upload possible, especially for files that are this large. */
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';
SELECT VERSION();

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Divvy_Trips_2016_Q1.csv'
INTO TABLE `2016_Q1`
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Only the first file of the first year processed without fault. I had to adjust the path to include extra inputs to be able to process.
-- This was the first time I asked AI: "What is my error here?" by copy/pasting the error message I recieved. I found this invaluable in error checking.
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Divvy_Trips_2016_04.csv"
INTO TABLE `2016_q2`
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Separate the date/time columns while altering the data types.
ALTER TABLE `2016_q1`
	ADD COLUMN start_date DATE,
    ADD COLUMN start_time TIME,
    ADD COLUMN end_date DATE,
    ADD COLUMN end_time TIME;

-- 2017 and on needed adjusted column names. Looking back, I probably would have ensured consistency at this stage to prevent further issues.    
ALTER TABLE `2017_q1`
	ADD COLUMN start_date DATE,
    ADD COLUMN starting_time TIME,
    ADD COLUMN end_date DATE,
    ADD COLUMN ending_time TIME;

/* This section: creates date columns, splits the datetime, and cleans the data to fit the syntax. */
UPDATE `2016_q1`
SET 
	start_date = DATE(STR_TO_DATE(starttime, '%m/%d/%Y %H:%i')),
	start_time = TIME(STR_TO_DATE(starttime, '%m/%d/%Y %H:%i')),
	end_date = DATE(STR_TO_DATE(stoptime, '%m/%d/%Y %H:%i')),
	end_time = TIME(STR_TO_DATE(stoptime, '%m/%d/%Y %H:%i'));

-- I discovered that the later datasets had a different format for the date/time.
UPDATE `2016_q2`
SET 
start_date = DATE(STR_TO_DATE(REPLACE(starttime,'"',''), '%m/%d/%Y %H:%i:%s')),
start_time = TIME(STR_TO_DATE(REPLACE(starttime,'"',''), '%m/%d/%Y %H:%i:%s')),
end_date = DATE(STR_TO_DATE(REPLACE(stoptime,'"',''), '%m/%d/%Y %H:%i:%s')),
end_time = TIME(STR_TO_DATE(REPLACE(stoptime,'"',''), '%m/%d/%Y %H:%i:%s'));

-- I started including the following script to ensure I didn't make a mistake with my adjustment.
SELECT start_date, start_time, end_date, end_time
FROM `2016_q2`
LIMIT 20;

-- I plan to find age, but first I need to be sure the column I'm using is consistent.
SELECT birthyear
FROM `2016_q1`
WHERE birthyear NOT REGEXP '^[0-9]+$'
	AND birthyear IS NOT NULL;
-- I then realized an easier way to do this same process a bit easier.
SELECT birthyear
FROM `2016_q2`
WHERE birthyear IS NOT NULL OR birthyear > 1916 OR birthyear != ' ';

ALTER TABLE `2016_q1`
MODIFY COLUMN birthyear INT;

-- Convert those blank spaces and birthyears over a 100 years to NULL values.
UPDATE `2016_q2`
SET birthyear = NULL
WHERE TRIM(birthyear) = '' OR birthyear < 1916;

-- Final check before aggregating.
SELECT birthyear
FROM `2016_q2`
LIMIT 50;

ALTER TABLE `2016_q2`
ADD COLUMN age INT;

UPDATE `2016_q2`
SET age = 2016 - birthyear
WHERE birthyear IS NOT NULL;

SELECT age
FROM `2016_q2`
LIMIT 10;

-- Elapsed riding time.
ALTER TABLE `2016_q1`
ADD COLUMN ride_length DECIMAL(10,2);

-- Edit data type before aggregating.
ALTER TABLE `2016_q2`
MODIFY COLUMN tripduration INT;

-- Convert seconds to minutes
UPDATE `2016_q1`
SET ride_length = tripduration/60;

SELECT ride_length
FROM `2016_q1`
LIMIT 20;

-- Add Day of Week
ALTER TABLE `2016_q1`
ADD COLUMN day_of_week VARCHAR(10);

UPDATE `2016_q1`
SET
	day_of_week = DAYNAME(start_date);

DESCRIBE `2016_q1`;

ALTER TABLE `2016_q1`
MODIFY COLUMN bikeid INT,
MODIFY COLUMN tripduration INT,
MODIFY COLUMN from_station_id INT,
MODIFY COLUMN trip_id INT;

-- There should be 0 records for each throughout each dataset, but this just double checks.
DELETE FROM `2016_q1`
WHERE trip_id IS NULL
OR bikeid IS NULL
OR tripduration IS NULL
OR from_station_id IS NULL
OR from_station_name IS NULL
OR to_station_id IS NULL
OR to_station_name IS NULL
OR usertype IS NULL
OR gender IS NULL
OR age IS NULL
OR start_date IS NULL
OR start_time IS NULL
OR end_date IS NULL
OR end_time IS NULL
OR ride_length IS NULL
OR day_of_week IS NULL;

DESCRIBE `2016_q1`;

ALTER TABLE `2016_q1`
MODIFY COLUMN to_station_id INT;