#Create a new database as database name "Pizza_sales"
CREATE DATABASE Pizza_sales;

#Working on Pizza_sales database
USE Pizza_sales;

-- Basics ETL done below

#Check the name of the header and its datatype of Orders & pizza_types tables
DESCRIBE orders;
DESCRIBE pizza_types;

#Change the header name of the Orders,pizza_types, and Pizzas tables
ALTER TABLE orders RENAME COLUMN DATE TO Order_date;
ALTER TABLE orders RENAME COLUMN TIME TO Order_time;
ALTER TABLE pizza_types RENAME COLUMN NAME TO Pizza_name;
ALTER TABLE pizzas RENAME COLUMN size TO pizza_size;

#Check the name of the header and its datatype of the Orders table
DESCRIBE orders;
SELECT * FROM orders;

#Change the datatype of the header inside the Orders table
ALTER TABLE orders MODIFY COLUMN Order_id INT NOT NULL PRIMARY KEY;
ALTER TABLE orders MODIFY COLUMN Order_date DATE NOT NULL;
ALTER TABLE orders MODIFY COLUMN Order_time TIME NOT NULL;

#Check the name of the header and its datatype of the Orders_details table
DESCRIBE order_details;
SELECT * FROM order_details;

#Change the datatype of the header inside the Orders_details table
ALTER TABLE order_details MODIFY COLUMN order_details_id INT NOT NULL PRIMARY KEY;
ALTER TABLE order_details MODIFY COLUMN order_id INT NOT NULL;
ALTER TABLE order_details MODIFY COLUMN pizza_id TEXT NOT NULL;
ALTER TABLE order_details MODIFY COLUMN quantity INT NOT NULL;

#Check the name of the header and its datatype of the Pizza_types table
DESCRIBE pizza_types;
SELECT * FROM pizza_types;
SELECT DISTINCT(LENGTH(pizza_type_id)) FROM pizza_types;
SELECT DISTINCT(LENGTH(category)) FROM pizza_types;
SELECT DISTINCT(LENGTH(Pizza_name)) FROM pizza_types;

#Change the datatype of the header inside the pizza_types table
ALTER TABLE pizza_types MODIFY COLUMN pizza_type_id VARCHAR(25) NOT NULL;
ALTER TABLE pizza_types MODIFY COLUMN pizza_name VARCHAR(50) NOT NULL ;
ALTER TABLE pizza_types MODIFY COLUMN category VARCHAR(18) NOT NULL;
ALTER TABLE pizza_types MODIFY COLUMN ingredients TEXT NOT NULL;

#Check the name of the header and its datatype of the pizzas table
DESCRIBE pizzas;
SELECT * FROM pizzas;

#Change the datatype of the header inside the pizzas table
ALTER TABLE pizzas MODIFY COLUMN pizza_id VARCHAR(25) NOT NULL;
ALTER TABLE pizzas MODIFY COLUMN pizza_type_id VARCHAR(25) NOT NULL;
ALTER TABLE pizzas MODIFY COLUMN pizza_size VARCHAR(4) NOT NULL;
ALTER TABLE pizzas MODIFY COLUMN price DECIMAL(4,2) NOT NULL;

# Now here we start the analysis

-- Retrieve the total number of orders placed.
SELECT COUNT(order_id) AS Order_recevied FROM orders;
/*Analysis:- "This query calculates the total number of orders placed in the dataset to understand the overall sales volume."*/


-- Calculate the total revenue generated from pizza sales.
SELECT
    ROUND(SUM(o.quantity * p.price),2) AS Total_revenue_generated
FROM
    order_details o 
        JOIN 
    pizzas p ON o.pizza_id = p.pizza_id;
/*Analysis:-"This query sums up the total revenue by multiplying the price of each pizza by the quantity sold, providing insights into the business’s 
           total earnings."*/


-- Identify the highest-priced pizza.
SELECT
    Pizza_name, 
    Pizza_id, 
    Category,  
    Pizza_Price  
FROM(
    SELECT
        pt.pizza_name,pt.pizza_type_id, 
        p.pizza_id,
        pt.category,
        p.price AS Pizza_price ,
        DENSE_RANK() OVER(ORDER BY p.price DESC) AS Highest_Price_Pizza
    FROM
        pizzas p 
            JOIN 
        pizza_types pt ON p.pizza_type_id = pt.pizza_type_id) 
        AS Pizza_details
WHERE
    Highest_Price_Pizza = 1;

# OR

SELECT
    pt.pizza_name, 
    p.pizza_id, 
    pt.category, 
    p.price AS Pizza_price
FROM
    pizzas p 
        JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY
    Pizza_price DESC
LIMIT 1;
/*Analysis:-"This query retrieves the highest-priced pizza from the menu, helping the business identify premium offerings."*/


-- Identify the most common pizza size ordered.
SELECT
    pizzas.pizza_Size, 
    COUNT(order_details.order_details_id) AS Most_common_size_ordered
FROM
    pizzas 
        JOIN 
    order_details ON pizzas.pizza_id=order_details.pizza_id
GROUP BY
    pizzas.pizza_size
ORDER BY
    Most_common_size_ordered DESC
LIMIT 1;
/*Analysis:-"This query counts the number of orders by pizza size to find out which size is most frequently ordered by customers."*/   


-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    p.pizza_id, 
    SUM(od.quantity) AS Pizza_Quanties
FROM
    order_details od 
        JOIN 
    pizzas p ON od.pizza_id = p.pizza_id 
GROUP BY
    p.pizza_id 
ORDER BY
    pizza_quanties DESC 
LIMIT 5;
   
# OR IF We have to address Pizza_Name, go with this

SELECT 
    pt.pizza_name,
    SUM(od.quantity) AS Pizza_Quanties
FROM
    pizza_types pt 
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id 
        JOIN 
    order_details od ON od.pizza_id = p.pizza_id 
GROUP BY
    pt.pizza_name 
ORDER BY
    pizza_quanties DESC 
LIMIT 5;
/*Analysis:-"This query ranks the top 5 pizzas based on the total quantity ordered, helping the business focus on its best-selling items."*/

   
-- Find the total quantity of each pizza category ordered.
SELECT
    pizza_types.category, 
    SUM(order_details.quantity) AS Total_qunatity_by_category
FROM
    pizzas 
        JOIN 
    order_details ON pizzas.pizza_id=order_details.pizza_id 
        JOIN 
    pizza_types ON pizzas.pizza_type_id= pizza_types.pizza_type_id
GROUP BY
    pizza_types.category
ORDER BY
    Total_qunatity_by_category DESC;
/*Analysis:-"This query joins the necessary tables to aggregate the total quantity of each pizza category, such as vegetarian or non-vegetarian pizzas"*/

   
-- Determine the distribution of orders by hour of the day.
SELECT
    HOUR(Order_time) AS Hour_wise,
    COUNT(order_id) AS Num_of_Orders
FROM
    orders
GROUP BY
    Hour_wise
ORDER BY
    Hour_wise;

# OR

WITH hourly_count AS(
    SELECT
        HOUR(Order_time) AS Hour_wise, 
        COUNT(order_id) AS Num_of_Orders
    FROM
        orders
    GROUP BY
        Hour_wise)
SELECT *, (LEAD(Num_of_Orders) OVER(ORDER BY Hour_wise) - Num_of_Orders) AS More_than_last_order FROM hourly_count;
/*Analysis:-"This query analyzes the time of day when orders were placed, helping the business identify peak hours for sales."*/

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT
    category,
    COUNT(pizza_type_id)
FROM
    pizza_types 
GROUP BY 
    category;
/*Analysis:-"This query joins relevant tables and calculates the distribution of each pizza category, providing deeper insights into 
             customer preferences."*/


-- Group the orders by date and calculate the average number of pizzas ordered per day.
WITH Ordered_Pizza AS (
    SELECT 
        o.order_date AS order_day, 
        SUM(od.quantity) AS Orderd_Per_day
    FROM 
        order_details od 
            JOIN 
        orders o ON o.Order_id =od.order_id 
    GROUP BY order_day)
SELECT ROUND(AVG(Orderd_Per_day),0) AS Avg_Pizza_Per_day FROM Ordered_Pizza ;

# OR
   
SELECT 
    ROUND(AVG(Avg_no_Pizzas)) AS Avg_Pizza_Per_day 
FROM (
      SELECT 
          o.order_date AS order_day, 
          SUM(od.quantity) AS Avg_no_Pizzas 
      FROM 
          order_details od 
              JOIN  
          orders o ON o.Order_id =od.order_id 
      GROUP BY o.order_date
     )
    AS Ordered_Pizzas;
/*Analysis:-"This query groups orders by date and computes the average number of pizzas ordered per day, helping the business understand daily
             sales trends."*/
   

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pt.pizza_name, 
    ROUND(SUM(p.price * od.quantity)) AS Revenue 
FROM 
    order_details od 
        JOIN 
    pizzas p ON od.pizza_id = p.pizza_id 
        JOIN 
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 
    pt.pizza_name
ORDER BY 
    Revenue DESC
LIMIT 3; 
/*Analysis:-"This query identifies the top 3 pizza types that generated the highest revenue, offering insights into the most profitable items."*/


-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT
    pt.category, 
    CONCAT(ROUND((SUM(p.price * od.quantity) / (SELECT
                                                  SUM(o.quantity * p.price) AS Total_revenue_generate
                                                FROM
                                                  order_details o 
                                                     JOIN 
                                                  pizzas p ON o.pizza_id = p.pizza_id)
                  ) * 100,2),"%") AS Percenatge_contribution
FROM
    order_details od 
        JOIN 
    pizzas p ON od.pizza_id = p.pizza_id 
        JOIN 
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 
    pt.category;   
/*Analysis:-"This query calculates the percentage contribution of each pizza type to the overall revenue, helping the business assess the 
             importance of each product in driving sales.*/


-- Analyze the cumulative revenue generated over time.
WITH sales AS(
    SELECT 
        orders.Order_date AS Date_column,
        SUM(p.price * od.quantity) AS Revenue 
    FROM 
        pizzas p 
            JOIN
        order_details od ON p.pizza_id = od.pizza_id 
            JOIN 
        orders ON orders.order_id  = od.order_id 
    GROUP BY orders.Order_date)
SELECT Date_column, SUM(Revenue) OVER(ORDER BY Date_column) AS Cumlative_Revenue FROM Sales;
   
# OR
   
SELECT 
    Order_date , 
    SUM(Revenue) OVER(ORDER BY Order_date DESC) AS Cumulative_Revenue
FROM(
    SELECT 
        orders.Order_date,
        SUM(p.price * od.quantity) AS Revenue 
    FROM
        pizzas p 
            JOIN
        order_details od ON p.pizza_id = od.pizza_id 
            JOIN 
        orders ON orders.order_id  = od.order_id 
    GROUP BY 
        orders.Order_date) AS Sales;
/*Analysis:-"This query tracks cumulative revenue over time to show how sales have grown, providing valuable insights for trend analysis."*/        


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT 
    Each_Pizza_category,
    Pizza_name, 
    Revenue 
FROM(
    SELECT 
        *, 
        DENSE_RANK() OVER(PARTITION BY Each_Pizza_category ORDER BY Revenue DESC) AS Ranking_Acc_Revenue 
    FROM(
        SELECT 
            pizza_types.category AS Each_Pizza_category,
            Pizza_types.pizza_name, 
            SUM(p.price * od.quantity) AS Revenue 
        FROM 
            pizza_types 
                JOIN 
            pizzas p ON pizza_types.pizza_type_id=p.pizza_type_id
                JOIN 
            order_details od ON p.pizza_id = od.pizza_id 
        GROUP BY 
            Each_Pizza_category, 
            pizza_types.pizza_name 
        ORDER BY 
            Each_Pizza_category ASC) 
        AS sales) 
    AS Pizza_Name_Revenue_Ranking 
WHERE Ranking_Acc_Revenue BETWEEN 1 AND 3;	
/*Analysis:-"This query identifies the top 3 pizza types with the highest revenue in each category, offering a more granular view of
             profitability across different product lines."*/


SELECT "THANK YOU" AS Message_For_You;
   
