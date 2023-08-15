USE edata;
# TRANSFORM DATE COLUMS INTO CORRECT FORMAT

-- SET SQL_SAFE_UPDATES=0; 
-- UPDATE shipping_dimen
-- SET Ship_Date= str_to_date(Ship_Date, '%d-%m-%Y');
-- UPDATE orders_dimen
-- SET Order_Date= str_to_date(Order_Date, '%d-%m-%Y');

-- 1. Using the columns of the tables of edata, create a table as combined table

SELECT *
INTO 
combined_table 
FROM 
(
SELECT 
cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, 
mf.Ord_id, mf.Prod_id, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Product_Base_Margin,
od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category,
sd.Ship_id, sd.Ship_Mode, sd.Ship_Date
FROM market_fact mf
INNER JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
INNER JOIN orders_dimen od ON mf.Ord_id = od.Ord_id
INNER JOIN prod_dimen pd ON mf.Prod_id = pd.Prod_id
INNER JOIN shipping_dimen sd ON mf.Ship_id = sd.Ship_id) A;

SELECT * FROM combined_table;

-- 2. Find the top 3 customers who have the maximum count of orders

SELECT Cust_id, COUNT(Ord_id) AS total_orders
FROM combined_table 
GROUP BY Cust_id
ORDER BY total_orders DESC
LIMIT 3;

-- 3. Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order Date and Ship Date 
ALTER TABLE combined_table
DROP COLUMN DaysTakenForDelivery;
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE combined_table
ADD COLUMN DaysTakenForDelivery INT;

UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF(Ship_Date ,Order_Date);

SELECT *
FROM combined_table;


-- 4. Find the customer whose order took the maximum time to get delivered.

SELECT Cust_id, Customer_Name, Order_Date, Ship_Date, DATEDIFF(Ship_Date, Order_Date) AS Max_day_delivered
FROM combined_table
Order BY Max_day_delivered DESC
LIMIT 1;

-- 5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011 ?

SELECT DISTINCT COUNT(Cust_id) AS total_uniquecustomer 
FROM combined_table
WHERE Order_Date BETWEEN "2011-01-01" AND "2011-01-31";

SELECT MONTH(Order_Date), COUNT(DISTINCT(Cust_id)) AS montly_regular_customer_amount
FROM combined_table A 
WHERE EXISTS 
( SELECT Cust_id
FROM combined_table B
WHERE YEAR(Order_Date)= 2011 AND MONTH(Order_Date) = 1
AND A.Cust_id=B.Cust_id)
AND YEAR(Order_Date)=2011
GROUP BY MONTH(Order_Date);

-- 6. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.

SELECT DISTINCT Cust_id, First_Order_Date, Third_Order_Date, DATEDIFF(Third_Order_Date,First_Order_Date) AS DaysElapsed
FROM
( SELECT Cust_id, MIN(Order_Date) AS First_Order_Date,
(SELECT Order_Date
FROM combined_table o2
WHERE o1.Cust_id=o2.Cust_id
ORDER BY Order_Date ASC
LIMIT 1 OFFSET 2) AS Third_Order_Date
FROM combined_table o1
GROUP BY Cust_id) subquery
ORDER BY Cust_id;

--7. Write a query that returns customers who purchased both product 11 and  product 14, as well as the ratio of these products to the total number of  products purchased by the customer

SELECT 
    Customer_Name, 
    SUM(CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) AS Nprod11,
    SUM(CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) AS Nprod14, SUM(Order_Quantity), 
	CONCAT('%',(SUM(CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END)+SUM(CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END))*100/SUM(Order_Quantity)) AS ratio
FROM
    combined_table
    GROUP BY Customer_Name
HAVING SUM(CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) AND
       SUM(CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) ;
       

