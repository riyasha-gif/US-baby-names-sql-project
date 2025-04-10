CREATE SCHEMA baby_names_db;
USE baby_names_db;

--
-- Table structure for table `names`
--

CREATE TABLE names (
  State CHAR(2),
  Gender CHAR(1),
  Year INT,
  Name VARCHAR(45),
  Births INT);

--
-- Table structure for table `regions`
--

CREATE TABLE regions (
  State CHAR(2),
  Region VARCHAR(45));

--
-- Insert data into table names
--

/* Launch mysql Command Prompt (PC)
Update root with my username and password 

> mysql -u root

> USE baby_names_db;

> SET GLOBAL local_infile=true;

> LOAD DATA LOCAL INFILE 'F:/IVY assignments/SQL JAN-MAR''25/FINAL PROJECT/names_data.csv'
INTO TABLE names
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n';

> quit;

-- Insert data into table regions*/


INSERT INTO regions VALUES ('AL', 'South'),
('AK', 'Pacific'),
('AZ', 'Mountain'),
('AR', 'South'),
('CA', 'Pacific'),
('CO', 'Mountain'),
('CT', 'New_England'),
('DC', 'Mid_Atlantic'),
('DE', 'South'),
('FL', 'South'),
('GA', 'South'),
('HI', 'Pacific'),
('ID', 'Mountain'),
('IL', 'Midwest'),
('IN', 'Midwest'),
('IA', 'Midwest'),
('KS', 'Midwest'),
('KY', 'South'),
('LA', 'South'),
('ME', 'New_England'),
('MD', 'South'),
('MA', 'New_England'),
('MN', 'Midwest'),
('MS', 'South'),
('MO', 'Midwest'),
('MT', 'Mountain'),
('NE', 'Midwest'),
('NV', 'Mountain'),
('NH', 'New England'),
('NJ', 'Mid_Atlantic'),
('NM', 'Mountain'),
('NY', 'Mid_Atlantic'),
('NC', 'South'),
('ND', 'Midwest'),
('OH', 'Midwest'),
('OK', 'South'),
('OR', 'Pacific'),
('PA', 'Mid_Atlantic'),
('RI', 'New_England'),
('SC', 'South'),
('SD', 'Midwest'),
('TN', 'South'),
('TX', 'South'),
('UT', 'Mountain'),
('VT', 'New_England'),
('VA', 'South'),
('WA', 'Pacific'),
('WV', 'South'),
('WI', 'Midwest'),
('WY', 'Mountain');


-- objective 1

/*popular girl name and popular boy name
and show how they have changed popularity over the years.*/

select name, sum(births) as num_babies
from names
where gender = "f"
group by name 
order by num_babies desc
limit 1; 

select name, sum(births) as num_babies
from names
where gender = "m"
group by name 
order by num_babies desc
limit 1; 

/*popularity trends overtime*/
select * from (
with girl_name as (
select year,name, sum(births) as num_babies
from names
where gender = "f"
group by year,name 
order by year 
)

select year, name, dense_rank() over (partition by year order by num_babies desc) as popularity
from girl_name) as popular_girl_names
where name = "jessica" ;

select * from (
with boy_name as (
select year,name, sum(births) as num_babies
from names
where gender = "m"
group by year,name 
order by year 
)

select year, name, dense_rank() over (partition by year order by num_babies desc) as popularity
from boy_name) as popular_boy_names
where name = "michael" ;


/*Find the names with the biggest jumps in popularity from the first year of the data set to the last year */
with 1980s_name as (
	with all_names as (
	select year,name, sum(births) as num_babies
	from names
	group by year,name 
	)
	select year, name, dense_rank() over (partition by year order by num_babies desc) as popularity
	from all_names
	where year = 1980),
2009s_name as(
	with all_names as (
	select year,name, sum(births) as num_babies
	from names
	group by year,name 
	)
	select year, name, dense_rank() over (partition by year order by num_babies desc) as popularity
	from all_names
	where year = 2009 ) 
    
    select  n1.year , n1.name, n1.popularity , 
			n2.year, n2.name , n2.popularity , 
           CAST(n2.popularity AS SIGNED) - CAST(n1.popularity AS SIGNED) AS diff
    from 1980s_name n1 inner join 2009s_name n2 on n1.name = n2.name
    order by diff;

/*For each year, return the 3 most popular girl names and 3 most popular boy names*/

WITH RankedNames AS (
    SELECT 
        year, 
        name, 
        gender,
        dense_RANK() OVER 
        (PARTITION BY year, gender
        ORDER BY births DESC) AS rnk
    FROM names
)
SELECT year, gender,name, rnk
FROM RankedNames
WHERE rnk <= 3
ORDER BY year,gender, rnk;

/*Compare popularity across decades*/

/*For each decade, return the 3 most popular girl names and 3 most popular boy names*/

WITH top_3 AS (
    SELECT (year - (year % 10)) AS decade,
    name, SUM(births) AS num_babies
    FROM names
    where gender = "F"
    GROUP BY decade, name, gender
),
ranking AS (
    SELECT  decade, name, num_babies,
           DENSE_RANK() OVER (PARTITION BY 
           decade ORDER BY num_babies DESC) AS rnk
    FROM top_3
)
SELECT decade, name, rnk
FROM ranking
WHERE rnk <= 3
ORDER BY decade, rnk;

-- boys

WITH top_3 AS (
    SELECT (year - (year % 10)) AS decade, name, SUM(births) AS num_babies
    FROM names
    where gender = "M"
    GROUP BY decade, name, gender
),
ranking AS (
    SELECT  decade, name, num_babies,
           DENSE_RANK() OVER (PARTITION BY decade ORDER BY num_babies DESC) AS rnk
    FROM top_3
)
SELECT decade, name, rnk
FROM ranking
WHERE rnk <= 3
ORDER BY decade, rnk;

-- objective 3

/*Compare popularity across regions*/
 /*Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)*/
 
 with clean_region as (
 select state , 
 case
	 when region = 'New England' then 'New_England'
	 else region
	 end as clean_region
from regions
 union
 select 'MI' as state , 'Midwest' as region
 )
 select clean_region , sum(births) as NumberOfBbabis
 from names n left join clean_region cr on n.state = cr.state
 group by clean_region 
 order by clean_region desc ;
 
 /*Return the 3 most popular girl names and 3 most popular boy names within each region*/
 
WITH clean_region AS (
    SELECT state, 
           CASE 
               WHEN region = 'New England' THEN 'New_England'
               ELSE region
           END AS clean_region
    FROM regions
    UNION
    SELECT 'MI' AS state, 'Midwest' AS region
),
girl_name AS (
    SELECT n.state, cr.clean_region, n.name, SUM(n.births) AS num_babies
    FROM names n left join clean_region cr on n.state = cr.state
    WHERE gender = 'F'
    GROUP BY n.state, cr.clean_region, n.name
),
rankings AS (
    SELECT clean_region, name, 
           DENSE_RANK() OVER (PARTITION BY clean_region ORDER BY num_babies DESC) AS rnk
    FROM girl_name
)
SELECT clean_region, name, rnk
FROM  rankings 
WHERE rnk <= 3 
ORDER BY clean_region, rnk;


-- boys

WITH clean_region AS (
    SELECT state, 
           CASE 
               WHEN region = 'New England' THEN 'New_England'
               ELSE region
           END AS clean_region
    FROM regions
    UNION
    SELECT 'MI' AS state, 'Midwest' AS region),
boy_name AS (
    SELECT n.state, cr.clean_region, n.name, SUM(n.births) AS num_babies
    FROM names n left join clean_region cr on n.state = cr.state
    WHERE gender = 'M'
    GROUP BY n.state, cr.clean_region, n.name),
rankings AS (
    SELECT clean_region, name, 
           DENSE_RANK() OVER (PARTITION BY 
           clean_region ORDER BY num_babies DESC) AS rnk
    FROM boy_name
)
SELECT clean_region, name, rnk
FROM  rankings 
WHERE rnk <= 3 
ORDER BY clean_region, rnk;

-- objective 4

/*Find the 10 most popular androgynous names (names given to both females and males) */

select distinct name 
from names
group by name 
having count(gender) =2 
limit 10;

/*Find the length of the shortest and longest names,
 and identify the most popular short names (those with the fewest characters) and long names (those with the most characters)*/
 
 select name, length(name) as name_lengths
 from names
 order by name_lengths desc; -- 15 char
 
 select name, length(name) as name_lengths
 from names
 order by name_lengths ;  -- 2 char
 
 select name , sum(births) as num_babies
 from names
 where length(name) in (2,15)
 group by name
 order by num_babies desc;
  -- ty among short and ryanchristopher among long are popular names.
  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 














































