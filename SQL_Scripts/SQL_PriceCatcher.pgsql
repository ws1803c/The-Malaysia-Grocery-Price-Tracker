-- ## IMPORT LOCAL DATASET
-- Create the empty table structure
CREATE TABLE price_catcher (
    date DATE,
    premise_code INT,
    item_code INT,
    price DECIMAL(10, 2)
);

CREATE TABLE lookup_item (
    item_code INT,
    item VARCHAR(255),
    unit VARCHAR(50),
    item_group VARCHAR(100),
    item_category VARCHAR(50)
);

CREATE TABLE lookup_premise (
    premise_code DECIMAL(10, 1),
    premise VARCHAR(100),
    address VARCHAR(500),
    premise_type VARCHAR(100),
    state VARCHAR(50),
    district VARCHAR(50)
);

-- Change the file path inside the quotes '' to match where you put your file
-- This is to upload the downloaded data onto the database
COPY price_catcher(date, premise_code, item_code, price)
FROM 'file_location'
DELIMITER ','
CSV HEADER;

COPY lookup_item(item_code, item, unit, item_group, item_category)
FROM 'file_location'
DELIMITER ','
CSV HEADER;

COPY lookup_premise(premise_code, premise, address, premise_type, state, district)
FROM 'file_location'
DELIMITER ','
CSV HEADER;

-- Check for Missing Values
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_dates,
    SUM(CASE WHEN premise_code IS NULL THEN 1 ELSE 0 END) AS missing_premises,
    SUM(CASE WHEN item_code IS NULL THEN 1 ELSE 0 END) AS missing_items,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_prices
FROM price_catcher;
-- No missing values

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN premise_code IS NULL THEN 1 ELSE 0 END) AS missing_premise_codes,
    SUM(CASE WHEN premise IS NULL THEN 1 ELSE 0 END) AS missing_premises,
    SUM(CASE WHEN address IS NULL THEN 1 ELSE 0 END) AS missing_addresses,
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS missing_states,
    SUM(CASE WHEN district IS NULL THEN 1 ELSE 0 END) AS missing_districts
FROM lookup_premise;
-- At least 2 missing rows

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN item_code IS NULL THEN 1 ELSE 0 END) AS missing_item_codes,
    SUM(CASE WHEN item IS NULL THEN 1 ELSE 0 END) AS missing_items,
    SUM(CASE WHEN unit IS NULL THEN 1 ELSE 0 END) AS missing_units,
    SUM(CASE WHEN item_group IS NULL THEN 1 ELSE 0 END) AS missing_item_groups,
    SUM(CASE WHEN item_category IS NULL THEN 1 ELSE 0 END) AS missing_item_category
FROM lookup_item;
-- At least 1 missing row

-- Locate and Remove what is actually missing
SELECT *
FROM lookup_premise
WHERE premise IS NULL;

SELECT *
FROM lookup_item
WHERE item IS NULL;

DELETE FROM lookup_premise
WHERE premise IS NULL;

DELETE FROM lookup_item
WHERE item IS NULL;

-- Convert the decimal premise_code into integer
ALTER TABLE lookup_premise
ALTER COLUMN premise_code TYPE INT USING premise_code::integer;

-- Create a view for the joined master dataset
CREATE VIEW master_price_catcher AS (
    SELECT
        p.date,
        p.premise_code,
        p.item_code,
        p.price,
        pr.premise,
        pr.address,
        pr.premise_type,
        pr.state,
        pr.district,
        i.item,
        i.unit,
        i.item_group,
        i.item_category
    FROM price_catcher p
    JOIN lookup_premise pr ON p.premise_code = pr.premise_code
    JOIN lookup_item i ON p.item_code = i.item_code
);

-- Confirm Finalised Master Data
SELECT * FROM master_price_catcher LIMIT 5;

-- Compare States with Item Group with descending Prices
SELECT
    state,
    ROUND(AVG(price), 2) AS avg_price
FROM master_price_catcher
WHERE item = 'TELUR AYAM GRED A'
GROUP BY 1
ORDER BY 2 DESC, 1;
-- Sarawak sells Grade A Eggs at RM 17.16 whereas Johor sells at RM 13.75 on average.

-- Market Competition
SELECT
    premise_type,
    ROUND(AVG(price), 2) AS avg_price
FROM master_price_catcher
GROUP BY 1
ORDER BY 2 DESC;
-- Pasar Mini has slightly higher average price than the others, while Borong has the lowest.

-- Price Volatility
SELECT
    item,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(stddev(price), 2) as price_volatility
FROM master_price_catcher
GROUP BY item
ORDER BY price_volatility DESC;
-- 	SOTONG KERING (SAIZ SERDAHANA) has 56.21 stddev whereas 5 items have near 0 stddev.
