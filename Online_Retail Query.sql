/*Introduction to Project
Project: Online Retail — Small Store Sales Analysis
Description: Clean and transform one year of sales data; 
create tables for different types of data in the original table; 
run business projections (annual sales, best time-of-day for sales, cancellation counts, etc...).

Usage:Open this file in SSMS.
Run sections in order.

Note: The CSV file attatched in the repo is the correct CSV for this SQL file.
The orignal CSV file from Kaggle listed in the read-me underwent preliminary data cleaning in Python.
*/


--The first step in this project was to convert the time data from NVarchar to actual time data types
--This code added new columns for the date and time-of-day so we can break down sales metrics by date and TOD
ALTER TABLE Portfolio.dbo.Online_Retail
ADD [Date] DATE,
    TOD TIME(0); --Time of Day

--This code parsed the time out of the text placing the date into the date column and the time into the TOD column
UPDATE Portfolio.dbo.Online_Retail
SET
  [Date] = TRY_CAST(TRY_PARSE(InvoiceDate AS datetime USING 'en-US') AS date),
  [TOD] = TRY_CAST(TRY_PARSE(InvoiceDate AS datetime USING 'en-US') AS time(0))
WHERE TRY_PARSE(InvoiceDate AS datetime USING 'en-US') IS NOT NULL;

--Verify the results
SELECT
InvoiceDate,
[Date],
TOD
FROM Portfolio.dbo.Online_Retail

--To continue improving the data set we need to check for NULL values
-- We also need to screen for NULLs that will impact business insights
SELECT
*
FROM Portfolio.dbo.Online_Retail
WHERE StockCode IS NULL OR [Description] IS NULL OR Quantity IS NULL OR InvoiceDate IS NULL OR UnitPrice IS NULL 
        OR CustomerID IS NULL OR Country IS NULL
--We see that sometimes the customer ID is missing but that is ok as it won't affect financial data

--One thing we need to address are the Description names that don't match the typical pattern
--In this case the typical pattern is all caps
SELECT
*
FROM Portfolio.dbo.Online_Retail
WHERE [Description] IS NULL OR len([Description]) < 8 --Many of the incorrect descriptions were short
ORDER BY len([Description]) DESC, [Description]

--everything under 5 characters was incorrect data and removed from the set
DELETE FROM Portfolio.dbo.Online_Retail
WHERE LEN(LTRIM(RTRIM([Description]))) <= 5;-- check results

--After exploring the descriptions we know that a correct description is meant to be all caps
--This allows us to view some of the problematic descriptions and come up with a solution
SELECT
*
FROM Portfolio.dbo.Online_Retail
WHERE PATINDEX('%[a-z]%', Description COLLATE Latin1_General_BIN2) > 0 AND --find all descriptions with lowercase letters
not (PATINDEX('%[0-9]g%', Description COLLATE Latin1_General_BIN2) > 0) AND --remove any where the lowercase is measuring grams
not (PATINDEX('%[0-9]cm%', Description) > 0) AND --or centimeters (note the removal of the "collate" parameter, 
                                                 --as "CM" was found in both lowercase and uppercase)
(PATINDEX('%[0-9]%', StockCode) > 0) --There are a few unique stockcodes that have no numbers in them (for things like Manuals and Discounts)
AND Description not like '%Gift Voucher%' --giftcards
AND Description != '3 TRADITIONAl BISCUIT CUTTERS  SET' --A specific item with a number in the description
AND StockCode != '23444' --Next day delivery fee
AND Description != 'FOLK ART GREETING CARD,pack/12' --another Description with a unique number pattern

--Changed about 200 descriptions that had a lowercase 'no' at the end and forced them to uppercase
--They now conform with the pattern
UPDATE Portfolio.dbo.Online_Retail
SET Description = UPPER(Description)
WHERE Description LIKE '% No';

--A few descriptions had an * and were written in lowercase
--This forced the Description to conform to uppercase
UPDATE Portfolio.dbo.Online_Retail
SET Description = UPPER(Description)
WHERE Description LIKE '%*%';

--Creating a new table to store the problematic data
--We don't want to delete it but it is not relevant to our analysis
SELECT TOP (0) *
    INTO Portfolio.dbo.Retail_Issues
    FROM Portfolio.dbo.Online_Retail;

--Now we can fill the new table and remove the incorrect data from our main table
 
DELETE MAIN --We are going to delete rows from the main table
OUTPUT deleted.* --those deleted rows will be used to fill our new table
INTO Portfolio.dbo.Retail_Issues
FROM Portfolio.dbo.Online_Retail AS MAIN
WHERE PATINDEX('%[a-z]%', MAIN.Description COLLATE Latin1_General_BIN2) > 0
  AND NOT (PATINDEX('%[0-9]g%', MAIN.Description COLLATE Latin1_General_BIN2) > 0)
  AND NOT (PATINDEX('%[0-9]cm%', MAIN.Description) > 0)
  AND (PATINDEX('%[0-9]%', MAIN.StockCode) > 0)
  AND MAIN.Description NOT LIKE '%Gift Voucher%'
  AND MAIN.Description <> '3 TRADITIONAl BISCUIT CUTTERS  SET'
  AND MAIN.StockCode <> '23444'
  AND MAIN.Description <> 'FOLK ART GREETING CARD,pack/12';

--New table is filled and the old one is clean
SELECT
*
FROM Portfolio.dbo.Retail_Issues

--Creating a column with total costs for each line item (quantity * unit price)
ALTER TABLE Portfolio.dbo.Online_Retail
ADD TotalAmount DECIMAL(18,2);  -- choose precision/scale appropriate for prices

--Filling the column
UPDATE Portfolio.dbo.Online_Retail
SET TotalAmount = Quantity * UnitPrice;


--Next step is to split the "Cancellation data" marked by a C in the InvoiceNo to a new table
SELECT
*
FROM Portfolio.dbo.Online_Retail
WHERE InvoiceNo like '%c%'

--Creating a new table
SELECT TOP (0) *
    INTO Portfolio.dbo.Cancellations
    FROM Portfolio.dbo.Online_Retail;

--Filling the table and removing the rows from our original table
DELETE R
OUTPUT deleted.*
INTO Portfolio.dbo.Cancellations
FROM Portfolio.dbo.Online_Retail AS R
WHERE R.InvoiceNo LIKE '%c%';


--Verifying the new table
SELECT
*
FROM Portfolio.dbo.Cancellations

--Looking at our orignal table we find more mismanaaged data. A large number of orders have a negative quantity.
--These were cancellations that were not marked correctly.

--Moving the data to the cancellations table
DELETE N
OUTPUT deleted.*
INTO Portfolio.dbo.Cancellations
FROM Portfolio.dbo.Online_Retail AS N
WHERE N.Quantity <= 0


--Now we can start looking at sales data and hopefully translate these into meaningful insights for the customer
--We will start with the simplest metrics, sales data for the year broken down by month
SELECT
MONTH(Date) AS 'Month',
SUM(TotalAmount) AS 'Total Sales'
FROM Portfolio.dbo.Online_Retail
GROUP BY YEAR(Date), MONTH(Date) --The data set is from Dec to Dec so we need to add in year to separate the 2 decembers
ORDER BY YEAR(Date), MONTH(Date)

/* What did we learn?
The highest sales seem to be in the Fall (Sep, Oct, Nov)
Revenue is consistent in the Summer and is the lowest in the Winter and Spring */

--Saving as a view for easier export to Tableau
CREATE VIEW dbo.MonthlySales AS
SELECT
MONTH(Date) AS 'Month',
SUM(TotalAmount) AS 'Total Sales'
FROM Portfolio.dbo.Online_Retail
GROUP BY YEAR(Date), MONTH(Date)

--Looking at what TOD is best for online sales
SELECT
DATEPART(HOUR, TOD) AS 'Hour',
SUM(TotalAmount) AS 'Total Sales'
FROM Portfolio.dbo.Online_Retail
GROUP BY DATEPART(HOUR, TOD)
ORDER BY DATEPART(HOUR, TOD)

/* What did we learn? 
It appears from here that the plurality of money is being made between 10 AM and 3 PM 
These are hours where kids are in school and businesses are open. */

--Now we want to look at which products make the most money and which are sold the most
--Which products make the most money?:
SELECT
TOP 10
[Description],
StockCode, --To identify non-product codes (M, D...)
SUM(TotalAmount) AS 'Total Sales'
FROM Portfolio.dbo.Online_Retail
GROUP BY [Description], StockCode
HAVING StockCode like '%[0-9]%' --We don't want to see sales for postage, manuals, etc....
ORDER BY SUM(TotalAmount) DESC

/*What did we learn? We can now see the big ticket items that make the company the most money.
These items should be well stocked and pushed in advertising. */

--What items are sold in the highest quantities?:

SELECT
TOP 10
[Description],
AVG(Quantity) as 'Avg Quantity'
FROM Portfolio.dbo.Online_Retail
WHERE StockCode like '%[0-9]%' -- now that we know problematic stock codes we can include this in a Where
GROUP BY [Description]
ORDER BY AVG(Quantity) DESC

--It appears that our top product is an outlier, let's check

SELECT
*
FROM Portfolio.dbo.Online_Retail
WHERE [Description] = 'PAPER CRAFT , LITTLE BIRDIE'
--This product was only ordered once, and in a very large quantity. Let's remove it from the list.

--Top products by quantity without the outlier
SELECT
TOP 10
[Description],
AVG(Quantity) as 'Avg Quantity'
FROM Portfolio.dbo.Online_Retail
WHERE StockCode like '%[0-9]%' AND [Description] != 'PAPER CRAFT , LITTLE BIRDIE'
GROUP BY [Description]
ORDER BY AVG(Quantity) DESC

/*What did we learn? We have here a list of 10 products that are sold, on average, in very high quantities.
This means it would be good business practice to keep these items
in stock at a high volume to ensure fast delivery times when orders come in. */

--Summation of our cancelled orders.
    SELECT
    COUNT(DISTINCT InvoiceNo) as 'Total Cancellations'
    FROM Portfolio.dbo.Cancellations

/*What did we learn? From all the orders made this year there were 4.6k cancellations. This is less than
1% of total orders. */

--Which items were returned the most?:
SELECT
TOP 10
[Description],
COUNT([Description]) as 'Total Cancelled'
FROM Portfolio.dbo.Cancellations
WHERE StockCode like '%[0-9]%'
GROUP BY [Description]
ORDER BY COUNT([Description]) DESC

/*What did we learn? The number one item returned is also the item that makes the most money.
The company should double check quality for this item so that sales remain final. 
The rest of the products were not top sellers so the company should look into why they were 
returned more than other items and then decide if they should
improve the items or discontinue them. */

--The final analysis for this project is a look at our customers.
--Which customers spent the most money?:
SELECT
TOP 10
CustomerID,
SUM(TotalAmount) as 'Total Spent this Year'
FROM Portfolio.dbo.Online_Retail
WHERE CustomerID is not null --There are too many NULLs in the customerID, missing out on sales data
GROUP BY CustomerID
ORDER BY SUM(TotalAmount) DESC

/* What did we learn? Now we know which customers are our biggest spenders. 
They should be nurtured as customers and offered
discounts, promotional materials, etc... */

--Let's dive into the orders of the top 3
CREATE VIEW dbo.Top3Clients AS --For later use in Tableau
SELECT
TOP 3
CustomerID,
SUM(TotalAmount) as 'Total Spent this Year'
FROM Portfolio.dbo.Online_Retail
WHERE CustomerID is not null
GROUP BY CustomerID

SELECT
*
FROM Portfolio.dbo.Online_Retail ONR
JOIN Portfolio.dbo.Top3Clients T3
ON ONR.CustomerID = T3.CustomerID
WHERE ONR.CustomerID = T3.CustomerID
ORDER BY ONR.CustomerID, ONR.InvoiceNo

--We list the orders above but let's breakdown what they are buying.
--Which items were purchased the most times? Recurring orders.
SELECT
ONR.CustomerID,
ONR.[Description],
COUNT(ONR.[Description]) as 'Times Ordered',
SUM(ONR.Quantity) as 'Amount Ordered'
FROM Portfolio.dbo.Online_Retail ONR
JOIN Portfolio.dbo.Top3Clients T3
ON ONR.CustomerID = T3.CustomerID
WHERE ONR.CustomerID = T3.CustomerID
GROUP BY ONR.CustomerID, ONR.[Description]
ORDER BY COUNT(ONR.[Description]) DESC

--Which items were sold in the highest volumes? Quantity.
SELECT
ONR.CustomerID,
ONR.[Description],
COUNT(ONR.[Description]) as 'Times Ordered',
SUM(ONR.Quantity) as 'Amount Ordered'
FROM Portfolio.dbo.Online_Retail ONR
JOIN Portfolio.dbo.Top3Clients T3
ON ONR.CustomerID = T3.CustomerID
WHERE ONR.CustomerID = T3.CustomerID
GROUP BY ONR.CustomerID, ONR.[Description]
ORDER BY SUM(ONR.Quantity) DESC


/* What did we learn? Customer 17850 is a huge customer, with almost 20 different orders 
over the year each time ordering in bulk. Customer 12583 orders less often but in large 
quantities. An effective business strategy would be to offer discounts to these customers on the products
they order in bulk. This way the company makes a larger sale and curries favor with the clients. */
