---------------------------------------------
-- Data Preparation
---------------------------------------------

-- Drop tables
DROP TABLE CYCLIST_TRIP_DATA;
DROP TABLE MEM_CAS_RIDES;
DROP TABLE YEAR_RIDES;
DROP TABLE YEAR_RIDES_CASUAL;
DROP TABLE YEAR_RIDES_MEMBERS;
DROP TABLE ROUND_RIDES;
DROP TABLE MEM_CAS_BIKES_RIDES;
DROP TABLE BIKES_RIDES;

-- Checking if all the tables have the same number of columns       
SELECT COUNT(*)
FROM USER_TAB_COLUMNS
WHERE table_name = 'TRIP_202004';

SELECT COUNT('elephant')
FROM USER_TAB_COLUMNS
WHERE table_name = 'TRIP_202007';

SELECT COUNT(*)
FROM USER_TAB_COLUMNS
WHERE table_name = 'TRIP_202010';

SELECT COUNT(*)
FROM USER_TAB_COLUMNS
WHERE table_name = 'TRIP_202103';

-- Union of all the 12 tables into a single data table
CREATE TABLE CYCLIST_TRIP_DATA AS 
(
    SELECT *
    FROM TRIP_202004
    
    UNION

    SELECT *
    FROM TRIP_202005

    UNION

    SELECT *
    FROM TRIP_202006

    UNION

    SELECT *
    FROM TRIP_202007
    
    UNION

    SELECT *
    FROM TRIP_202008

    UNION

    SELECT *
    FROM TRIP_202009

    UNION

    SELECT *
    FROM TRIP_202010
    
    UNION

    SELECT *
    FROM TRIP_202011

    UNION

    SELECT *
    FROM TRIP_202012

    UNION

    SELECT *
    FROM TRIP_202101
    
    UNION

    SELECT *
    FROM TRIP_202102

    UNION

    SELECT *
    FROM TRIP_202103
);

---------------------------------------------
-- Data Exploration
---------------------------------------------

-- Checking if table exists
SELECT table_name
FROM USER_TABLES WHERE table_name = 'CYCLIST_TRIP_DATA';

-- View table
SELECT *
FROM CYCLIST_TRIP_DATA;

-- Find the number of rides by casual-members and rides by annual-members
SELECT MEMBER_CASUAL, COUNT(*)
FROM CYCLIST_TRIP_DATA
GROUP BY MEMBER_CASUAL;

-- Counting rides ending at each docking station
SELECT END_STATION_ID, END_STATION_NAME, COUNT(1) AS rides
FROM CYCLIST_TRIP_DATA
GROUP BY END_STATION_ID, END_STATION_NAME
ORDER BY rides DESC;

-- Counting rides starting at each docking station
SELECT START_STATION_NAME, COUNT(1) AS rides
FROM CYCLIST_TRIP_DATA
GROUP BY START_STATION_NAME
ORDER BY rides DESC;

-- Count number of round trips
SELECT START_STATION_ID, END_STATION_ID,RIDEABLE_TYPE,MEMBER_CASUAL
FROM CYCLIST_TRIP_DATA
WHERE START_STATION_ID = END_STATION_ID;

SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA
WHERE START_STATION_ID = END_STATION_ID;

-- Counting total number of trips
SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA;

-- Counting number of rideable type
SELECT rideable_type, COUNT(1)
FROM CYCLIST_TRIP_DATA
GROUP BY rideable_type;

---------------------------------------------
-- Data Quality Check
---------------------------------------------

-- See if anything other than member or casual is present in MEMBER_CASUAL
SELECT DISTINCT MEMBER_CASUAL
FROM CYCLIST_TRIP_DATA;

-- Check the ranges of latitudes and longitudes
SELECT MIN(end_lng),MAX(end_lng),
       MIN(end_lat),MAX(end_lat), 
       MIN(start_lng),MAX(start_lng),
       MIN(start_lat),MAX(start_lat)
FROM CYCLIST_TRIP_DATA;

-- Check if ride ids (which are supposed to be unique) having count >1
SELECT ride_id, COUNT(1)
FROM CYCLIST_TRIP_DATA
GROUP BY ride_id
HAVING COUNT(1) > 1;

-- Checking for nulls in rows
SELECT *
FROM CYCLIST_TRIP_DATA
WHERE started_at IS NULL OR ended_at IS NULL;

-- Checking for rows where column value is absent
-- We want to investigate if the blank fields are either due to empty strings, or null , or whitespaces

-- Below query is to counter fileds which only have whitespaces 
SELECT COUNT (*) 
FROM CYCLIST_TRIP_DATA 
WHERE TRIM(START_STATION_ID) IS NULL OR TRIM(START_STATION_NAME) IS NULL;

-- Visual studio code shows null entries as blank fields.counting number of nulls
-- Checking on start and end stations
SELECT COUNT (*) 
FROM CYCLIST_TRIP_DATA 
WHERE START_STATION_ID IS NULL OR START_STATION_NAME IS NULL;

SELECT COUNT (*) 
FROM CYCLIST_TRIP_DATA 
WHERE END_STATION_ID IS NULL OR END_STATION_NAME IS NULL;

SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA
WHERE START_LAT IS NULL OR END_LAT IS NULL;

SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA
WHERE START_LNG IS NULL OR END_LNG IS NULL;

SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA
WHERE MEMBER_CASUAL IS NULL;

SELECT COUNT(*)
FROM CYCLIST_TRIP_DATA
WHERE RIDEABLE_TYPE IS NULL;

---------------------------------------------
-- Data Cleaning
---------------------------------------------

-- Delete all rows where any field is null
-- Below query deletes 1,95,057 rows
DELETE
FROM CYCLIST_TRIP_DATA
WHERE RIDE_ID IS NULL
OR RIDEABLE_TYPE IS NULL
OR STARTED_AT IS NULL
OR ENDED_AT IS NULL
OR START_STATION_NAME IS NULL
OR START_STATION_ID IS NULL
OR END_STATION_NAME IS NULL
OR END_STATION_ID IS NULL
OR START_LAT IS NULL
OR START_LNG IS NULL
OR END_LAT IS NULL
OR END_LNG IS NULL
OR MEMBER_CASUAL IS NULL;

-- Identify and exclude data with anomalies
-- 10743 rows deleted.

DELETE
FROM CYCLIST_TRIP_DATA
WHERE STARTED_AT >= ENDED_AT;

-- Checking if ride ids still have count >1
SELECT ride_id, COUNT(1)
FROM CYCLIST_TRIP_DATA
GROUP BY ride_id
HAVING COUNT(1) > 1;

-- Check again for any nulls
SELECT COUNT (*) 
FROM CYCLIST_TRIP_DATA 
WHERE START_STATION_ID IS NULL OR START_STATION_NAME IS NULL;

---------------------------------------------
-- Tables for Visualization
---------------------------------------------

-- Calculate trip length
ALTER TABLE CYCLIST_TRIP_DATA
ADD trip_duration_secs NUMBER;

-- Create new column trip duration secs
UPDATE CYCLIST_TRIP_DATA
SET trip_duration_secs = EXTRACT(HOUR FROM (ended_at-started_at))*3600 + EXTRACT(MINUTE FROM (ended_at-started_at))*60 + EXTRACT(SECOND FROM (ended_at-started_at));

-- Number of rides for casual and members
CREATE TABLE MEM_CAS_RIDES AS
    SELECT MEMBER_CASUAL, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    GROUP BY MEMBER_CASUAL
    ORDER BY COUNT(*) DESC;

-- Member	1936040
-- Casual	1347908

-- Count of rides for each bike type
CREATE TABLE BIKES_RIDES AS
    SELECT RIDEABLE_TYPE, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    GROUP BY RIDEABLE_TYPE
    ORDER BY COUNT(*) DESC;

-- Distribution of members and casuals for each bike type
CREATE TABLE MEM_CAS_BIKES_RIDES AS
    SELECT RIDEABLE_TYPE, MEMBER_CASUAL, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    GROUP BY RIDEABLE_TYPE,MEMBER_CASUAL
    ORDER BY RIDEABLE_TYPE ASC, COUNT(*) DESC;

-- Count round trips for each bike type and membership type
CREATE TABLE ROUND_RIDES AS
    SELECT START_STATION_NAME, COUNT(*) AS NO_OF_ROUND_TRIPS, RIDEABLE_TYPE, MEMBER_CASUAL
    FROM CYCLIST_TRIP_DATA
    WHERE START_STATION_ID = END_STATION_ID
    GROUP BY START_STATION_NAME, RIDEABLE_TYPE, MEMBER_CASUAL
    ORDER BY START_STATION_NAME, COUNT(*) DESC, RIDEABLE_TYPE;

-- Distribution of casual and member rides across the year
CREATE TABLE YEAR_RIDES AS
    SELECT TO_CHAR(STARTED_AT,'MON-YYYY') AS MON_YEAR, MEMBER_CASUAL, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    GROUP BY TO_CHAR(STARTED_AT,'MON-YYYY'),MEMBER_CASUAL;

CREATE TABLE YEAR_RIDES_CASUAL AS
    SELECT TO_CHAR(STARTED_AT,'MON-YYYY') AS MON_YEAR, MEMBER_CASUAL, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    WHERE MEMBER_CASUAL = 'casual'
    GROUP BY TO_CHAR(STARTED_AT,'MON-YYYY'),MEMBER_CASUAL;

CREATE TABLE YEAR_RIDES_MEMBERS AS
    SELECT TO_CHAR(STARTED_AT,'MON-YYYY') AS MON_YEAR, MEMBER_CASUAL, COUNT(*) AS NO_OF_RIDES
    FROM CYCLIST_TRIP_DATA
    WHERE MEMBER_CASUAL = 'member'
    GROUP BY TO_CHAR(STARTED_AT,'MON-YYYY'),MEMBER_CASUAL;
