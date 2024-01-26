-- Skills utilized: 
-- Creating and modifying databases and tables 
-- CTE
-- Window functions
-- CASE statements
-- Removing duplicates 
-- Data cleaning

-- Rename table

ALTER TABLE "Nashville_houses"
RENAME TO house;

-- create backup table 

CREATE TABLE house_bkp1
as SELECT * FROM house

SELECT * FROM house

--format sale_date 

ALTER TABLE house 
add column new_sale_date DATE

UPDATE house
SET new_sale_date = TO_DATE(sale_date, 'Month DD, YYYY');

SELECT * FROM house

-- Fill in missing property address

SELECT h1.parcel_id, h1.property_address,h2.parcel_id, h2.property_address,COALESCE(h1.property_address,h2.property_address)
FROM house h1
JOIN house h2 
ON h1.parcel_id = h2.parcel_id 
AND h1.unique_id <> h2.unique_id
AND h1.property_address is null

-- as we can see above we have multiple parcel id with same property address yet some address are empty
-- Populating property address using parcel_id column 

UPDATE house h1
SET property_address = COALESCE(h1.property_address, h2.property_address)
FROM house h2 
WHERE h1.parcel_id = h2.parcel_id 
  AND h1.unique_id <> h2.unique_id
  AND h1.property_address IS NULL;
  
  
-- Seperate address into individual columns (Address,City,State)

SELECT property_address FROM house

SELECT SUBSTRING(property_address,1,POSITION(',' IN property_address)-1) AS address FROM house
SELECT SUBSTRING(property_address,POSITION(',' IN property_address)+1) AS address FROM house

ALTER TABLE house 
ADD COLUMN property_split_address varchar(300)

UPDATE house
SET property_split_address = SUBSTRING(property_address,1,POSITION(',' IN property_address)-1)

ALTER TABLE house 
ADD COLUMN property_split_city varchar(300)

UPDATE house
SET property_split_city = SUBSTRING(property_address,POSITION(',' IN property_address)+1)

--Split OwnerAddress

SELECT owner_address FROM house

-- Example: Splitting an address string and extracting street, city, and state
SELECT
  SPLIT_PART('410 ROSEHILL CT, GOODLETTSVILLE, TN', ',', 1) AS street,
  SPLIT_PART('410 ROSEHILL CT, GOODLETTSVILLE, TN', ',', 2) AS city,
  SPLIT_PART('410 ROSEHILL CT, GOODLETTSVILLE, TN', ',', 3) AS state;
  
-- Create 3 new columns street, city, and state in data

ALTER TABLE house 
ADD COLUMN owner_property_street varchar(300)

UPDATE house
SET owner_property_street = SPLIT_PART(owner_address, ',', 1)

ALTER TABLE house 
ADD COLUMN owner_property_city varchar(300)

UPDATE house
SET owner_property_city = SPLIT_PART(owner_address, ',', 2)

ALTER TABLE house 
ADD COLUMN owner_property_state varchar(300)

UPDATE house
SET owner_property_state = SPLIT_PART(owner_address, ',', 3)

SELECT * FROM house


-- Modify sold as vacant to ensure consistent input 

SELECT DISTINCT(sold_as_vacant),count(*) FROM house
GROUP BY sold_as_vacant

-- CONVERT N to NO and Y to Yes 

SELECT *,
CASE 
	WHEN sold_as_vacant = 'Y' THEN 'Yes'
	WHEN sold_as_vacant = 'N' THEN 'No'
	ELSE  sold_as_vacant
	END AS sold_as_vacant
FROM house 

UPDATE house
SET sold_as_vacant = CASE 
						WHEN sold_as_vacant = 'Y' THEN 'Yes'
						WHEN sold_as_vacant = 'N' THEN 'No'
						ELSE  sold_as_vacant
						END
						
-- Remove duplicates if values match in (parcel_id,property_address,sale_price,sale_date,legal_reference)
-- Have 104 duplicate records based off this condition 

with cte AS(
SELECT *,
Row_number() OVER(partition by 
				 parcel_id,
				 property_address,
				 sale_price,
				 sale_date,
				 legal_reference
				 ) as rn 
FROM house 
) 
DELETE FROM house 
WHERE unique_id in (
SELECT unique_id FROM cte
WHERE cte.rn > 1
)

-- CHECK TO SEE IF ANY REMAIN (no rows returned)
with cte AS(
SELECT *,
Row_number() OVER(partition by 
				 parcel_id,
				 property_address,
				 sale_price,
				 sale_date,
				 legal_reference
				 ) as rn 
FROM house 
)
	
SELECT * FROM cte 
WHERE cte.rn > 1

-- Alternative solution to remove duplicates (using backup table)

CREATE TABLE house_bkp AS
SELECT DISTINCT ON (parcel_id, property_address, sale_price, sale_date, legal_reference)
  *
FROM house
ORDER BY parcel_id, property_address, sale_price, sale_date, legal_reference

TRUNCATE TABLE house;

insert into house
SELECT * FROM house_bkp;

DROP TABLE house_bkp;

-- Delete unwanted columns

ALTER TABLE house
DROP COLUMN owner_address,
DROP COLUMN property_address,
DROP COLUMN sale_date;

SELECT * FROM house








