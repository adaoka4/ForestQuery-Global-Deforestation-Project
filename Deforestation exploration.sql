-- VIEW

-- Drop the view if it already exists
DROP VIEW IF EXISTS forestation;

-- Create the forestation view
CREATE VIEW forestation AS
SELECT
    f.country_code AS forest_country_code,
    f.country_name AS forest_country_name,
    f.year AS forest_year,
    f.forest_area_sqkm,
    l.country_code AS land_country_code,
    l.country_name AS land_country_name,
    l.year AS land_year,
    l.total_area_sq_mi,
    (f.forest_area_sqkm / (l.total_area_sq_mi * 2.59)) * 100 AS percent_land_as_forest,
    r.country_code AS region_country_code,
    r.country_name AS region_country_name,
    r.region,
    r.income_group
FROM
    forest_area f
    INNER JOIN land_area l ON f.country_code = l.country_code AND f.year = l.year
    INNER JOIN regions r ON r.country_code = l.country_code;


-- 1. GLOBAL SITUATION

-- Select forest area for the world in 1990
SELECT forest_area_sqkm
FROM forestation
WHERE forest_year = 1990 AND region_country_name = 'World';

-- Select forest area for the world in 2016
SELECT forest_area_sqkm
FROM forestation
WHERE forest_year = 2016 AND region_country_name = 'World';


-- Calculate the difference in forest area between 1990 and 2016 for the world
WITH forest_area_sqkm_1990 AS (
    SELECT forest_area_sqkm as sqkm_1990
    FROM forestation
    WHERE forest_year = 1990 AND region_country_name = 'World'
), forest_area_sqkm_2016 AS (
    SELECT forest_area_sqkm as sqkm_2016
    FROM forestation
    WHERE forest_year = 2016 AND region_country_name = 'World'
)
SELECT (sqkm_1990 - sqkm_2016) AS diff
FROM forest_area_sqkm_1990, forest_area_sqkm_2016;

-- Calculate the percentage difference in forest area between 1990 and 2016 for the world
WITH forest_area_sqkm_1990 AS (
    SELECT forest_area_sqkm as sqkm_1990
    FROM forestation
    WHERE forest_year = 1990 AND region_country_name = 'World'
), forest_area_sqkm_2016 AS (
    SELECT forest_area_sqkm as sqkm_2016
    FROM forestation
    WHERE forest_year = 2016 AND region_country_name = 'World'
)
SELECT (sqkm_1990 - sqkm_2016) / sqkm_1990 * 100 AS perc_diff
FROM forest_area_sqkm_1990, forest_area_sqkm_2016;


-- Select the country with the largest land area in 2016
WITH land_area_sqkm_2016 AS (
    SELECT
        land_country_name,
        total_area_sq_mi * 2.59 AS land_area_sqkm
    FROM forestation
    WHERE forest_year = 2016
)
SELECT
    land_country_name,
    land_area_sqkm
FROM
    land_area_sqkm_2016
WHERE
    land_area_sqkm < 1324449
ORDER BY land_area_sqkm DESC
LIMIT 1;


-- 2. REGIONAL OUTLOOK

-- Calculate the percentage of forest area in the world for the year 2016
SELECT
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as world_percent_forest
FROM
    forestation
WHERE
    forest_year = 2016 AND region = 'World'
GROUP BY
    region, forest_year;

-- Calculate the region with the highest percentage of forest area for the year 2016
SELECT
    region,
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest
FROM
    forestation
WHERE
    forest_year = 2016
GROUP BY
    region
ORDER BY
    percent_forest DESC
LIMIT 1;

-- Calculate the region with the lowest percentage of forest area for the year 2016
SELECT
    region,
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest
FROM
    forestation
WHERE
    forest_year = 2016
GROUP BY
    region
ORDER BY
    percent_forest ASC
LIMIT 1;

-- Calculate the percentage of forest area in the world for the year 1990
SELECT
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as world_percent_forest
FROM
    forestation
WHERE
    forest_year = 1990 AND region = 'World'
GROUP BY
    region, forest_year;

-- Calculate the region with the highest percentage of forest area for the year 1990
SELECT
    region,
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest
FROM
    forestation
WHERE
    forest_year = 1990
GROUP BY
    region
ORDER BY
    percent_forest DESC
LIMIT 1;

-- Calculate the region with the lowest percentage of forest area for the year 1990
SELECT
    region,
    ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest
FROM
    forestation
WHERE
    forest_year = 1990
GROUP BY
    region
ORDER BY
    percent_forest ASC
LIMIT 1;

-- Calculate the regions where the forest area decreased from 1990 to 2016
WITH
    t1 AS
    (
        SELECT
            region,
            ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest_1990
        FROM
            forestation
        WHERE
            forest_year = 1990
        GROUP BY
            region
        ORDER BY
            region ASC
    ),
    t2 AS
    (
        SELECT
            region,
            ROUND((SUM(forest_area_sqkm) * 100 / SUM(total_area_sq_mi * 2.59))::numeric, 2) as percent_forest_2016
        FROM
            forestation
        WHERE
            forest_year = 2016
        GROUP BY
            region
        ORDER BY
            region ASC
    )
SELECT 
    t1.region,
    t1.percent_forest_1990,
    t2.percent_forest_2016
FROM 
    t1
INNER JOIN 
    t2
ON 
    t1.region = t2.region
WHERE  
    t1.percent_forest_1990 > t2.percent_forest_2016 AND t1.region != 'World';



-- 3. COUNTRY-LEVEL DETAIL

-- A. SUCCESS STORIES

-- Calculate the countries with the largest increase in forest area from 1990 to 2016
WITH
  t1 AS
    (SELECT
      region_country_name,
      ROUND((total_area_sq_mi * 2.59)::numeric, 2) as land_area_sqkm_1990,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_1990
    FROM
      forestation
    WHERE
      forest_year = 1990
    ORDER BY
      region_country_name ASC),
  t2 AS
    (SELECT
      region_country_name,
      ROUND((total_area_sq_mi * 2.59)::numeric, 2) as land_area_sqkm_2016,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_2016
    FROM
      forestation
    WHERE
      forest_year = 2016
    ORDER BY
      region_country_name ASC)
SELECT
  t1.region_country_name,
  t1.land_area_sqkm_1990,
  t2.land_area_sqkm_2016,
  t1.country_forest_sqkm_1990,
  t2.country_forest_sqkm_2016,
  (t2.country_forest_sqkm_2016 - t1.country_forest_sqkm_1990) as diff
FROM
  t1
INNER JOIN
  t2 ON t1.region_country_name = t2.region_country_name
WHERE
  t1.country_forest_sqkm_1990 < t2.country_forest_sqkm_2016
ORDER BY
  diff DESC
LIMIT 5;


-- Calculate the countries with the largest percentage increase in forest area from 1990 to 2016
WITH
  t1 AS
    (SELECT
      region_country_name,
      ROUND((total_area_sq_mi * 2.59)::numeric, 2) as land_area_sqkm_1990,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_1990
    FROM
      forestation
    WHERE
      forest_year = 1990
    ORDER BY
      region_country_name ASC),
  t2 AS
    (SELECT
      region_country_name,
      ROUND((total_area_sq_mi * 2.59)::numeric, 2) as land_area_sqkm_2016,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_2016
    FROM
      forestation
    WHERE
      forest_year = 2016
    ORDER BY
      region_country_name ASC)
SELECT
  t1.region_country_name,
  t1.land_area_sqkm_1990,
  t2.land_area_sqkm_2016,
  t1.country_forest_sqkm_1990,
  t2.country_forest_sqkm_2016,
  (t2.country_forest_sqkm_2016 - t1.country_forest_sqkm_1990) as diff,
  ROUND((((t2.country_forest_sqkm_2016 - t1.country_forest_sqkm_1990) / t1.country_forest_sqkm_1990) * 100)::numeric, 2) as perc_diff
FROM
  t1
INNER JOIN
  t2 ON t1.region_country_name = t2.region_country_name
WHERE
  t1.country_forest_sqkm_1990 < t2.country_forest_sq

km_2016
ORDER BY
  perc_diff DESC
LIMIT 5;


-- B. LARGEST CONCERNS

-- Calculate the regions with the largest decrease in forest area from 1990 to 2016
WITH
  t1 AS
    (SELECT
      region_country_name,
      region,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_1990
    FROM
      forestation
    WHERE
      forest_year = 1990
    ORDER BY
      region_country_name ASC),
  t2 AS
    (SELECT
      region_country_name,
      region,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_2016
    FROM
      forestation
    WHERE
      forest_year = 2016
    ORDER BY
      region_country_name ASC)
SELECT
  t1.region_country_name,
  t1.region,
  t1.country_forest_sqkm_1990,
  t2.country_forest_sqkm_2016,
  (t1.country_forest_sqkm_1990 - t2.country_forest_sqkm_2016) as diff
FROM
  t1
INNER JOIN
  t2 ON t1.region_country_name = t2.region_country_name AND t1.region = t2.region
WHERE
  (t1.country_forest_sqkm_1990 > t2.country_forest_sqkm_2016) AND t1.region_country_name != 'World'
ORDER BY
  diff DESC
LIMIT 5;


-- Calculate the regions with the largest percentage decrease in forest area from 1990 to 2016
WITH
  t1 AS
    (SELECT
      region_country_name,
      region,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_1990
    FROM
      forestation
    WHERE
      forest_year = 1990
    ORDER BY
      region_country_name ASC),
  t2 AS
    (SELECT
      region_country_name,
      region,
      ROUND(forest_area_sqkm::numeric, 2) as country_forest_sqkm_2016
    FROM
      forestation
    WHERE
      forest_year = 2016
    ORDER BY
      region_country_name ASC)
SELECT
  t1.region_country_name,
  t1.region,
  t1.country_forest_sqkm_1990,
  t2.country_forest_sqkm_2016,
  (t1.country_forest_sqkm_1990 - t2.country_forest_sqkm_2016) as diff,
  ROUND((((t2.country_forest_sqkm_2016 - t1.country_forest_sqkm_1990) / t1.country_forest_sqkm_1990) * 100)::numeric, 2) as perc_diff
FROM
  t1
INNER JOIN
  t2 ON t1.region_country_name = t2.region_country_name AND t1.region = t2.region
WHERE
  (t1.country_forest_sqkm_1990 > t2.country_forest_sqkm_2016) AND t1.region_country_name != 'World'
ORDER BY
  perc_diff ASC
LIMIT 5;


-- C. QUARTILES

-- Calculate the quartiles of percent land as forest for countries in 2016
WITH
  forestation_perc AS
    (SELECT
      forest_country_name,
      region,
      percent_land_as_forest
    FROM
      forestation
    WHERE
      forest_year = 2016 AND percent_land_as_forest IS NOT NULL AND forest_country_name !=

 'World'
    ORDER BY
      percent_land_as_forest DESC),
  forestation_quart AS
    (SELECT
      forest_country_name,
      region,
      percent_land_as_forest,
      CASE
        WHEN percent_land_as_forest < 25 THEN '1'
        WHEN percent_land_as_forest BETWEEN 25 AND 50 THEN '2'
        WHEN percent_land_as_forest BETWEEN 50 AND 75 THEN '3'
        ELSE '4'
      END AS forestation_quartiles
    FROM
      forestation_perc
    ORDER BY
      percent_land_as_forest DESC)
SELECT
  forestation_quartiles,
  COUNT(forest_country_name)
FROM
  forestation_quart
GROUP BY
  forestation_quartiles
ORDER BY
  forestation_quartiles ASC;


-- Calculate the countries in the highest quartile (quartile 4) for percent land as forest in 2016
WITH
  forestation_perc AS
    (SELECT
      forest_country_name,
      region,
      percent_land_as_forest
    FROM
      forestation
    WHERE
      forest_year = 2016 AND percent_land_as_forest IS NOT NULL AND forest_country_name != 'World'
    ORDER BY
      percent_land_as_forest DESC),
  forestation_quart AS
    (SELECT
      forest_country_name,
      region,
      percent_land_as_forest,
      CASE
        WHEN percent_land_as_forest < 25 THEN '1'
        WHEN percent_land_as_forest BETWEEN 25 AND 50 THEN '2'
        WHEN percent_land_as_forest BETWEEN 50 AND 75 THEN '3'
        ELSE '4'
      END AS forestation_quartiles
    FROM
      forestation_perc
    ORDER BY
      percent_land_as_forest DESC)
SELECT
  forest_country_name,
  region,
  percent_land_as_forest,
  forestation_quartiles
FROM
  forestation_quart
WHERE
  forestation_quartiles = '4';
