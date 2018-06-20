--SQL practice
--1.Show the customer name for all customers who have ever made a payment over $100,000.
SELECT A.CUSTOMERNAME
FROM CUSTOMERS A
JOIN PAYMENTS B
ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
WHERE B.AMOUNT>100000
GROUP BY A.CUSTOMERNAME

--2.Show the product code, product name, and quantity in stock of all products that have a purchase price greater than the average.
SELECT PRODUCTCODE, PRODUCTNAME, QUANTITYINSTOCK
FROM PRODUCTS
WHERE BUYPRICE>(SELECT AVG(BUYPRICE) FROM PRODUCTS)

--3.Show the product name, product description, and product line for the product in each product line that has the highest volume of gross revenue
SELECT B.PRODUCTNAME, B.PRODUCTDESCRIPTION, B.PRODUCTLINE
FROM(SELECT PRODUCTCODE, SUM(QUANTITYORDERED*PRICEEACH) PROFIT
    FROM ORDERDETAILS 
    GROUP BY PRODUCTCODE) A
JOIN(SELECT PRODUCTCODE, PRODUCTNAME, PRODUCTDESCRIPTION, PRODUCTLINE FROM PRODUCTS) B
ON A.PRODUCTCODE=B.PRODUCTCODE
WHERE A.PROFIT IN (SELECT MAX(X.PROFIT)
                   FROM(SELECT PRODUCTCODE, SUM(QUANTITYORDERED*PRICEEACH) PROFIT
                         FROM ORDERDETAILS 
                         GROUP BY PRODUCTCODE) X
                   JOIN(SELECT PRODUCTCODE, PRODUCTNAME, PRODUCTDESCRIPTION, PRODUCTLINE FROM PRODUCTS) Y
                   ON X.PRODUCTCODE=Y.PRODUCTCODE
                   GROUP BY Y.PRODUCTLINE)

--4.Show the employee first name, last name, and job title for all employees with the job title of “Sales Rep”.
SELECT FIRSTNAME, LASTNAME, JOBTITLE
FROM EMPLOYEES
WHERE JOBTITLE='Sales Rep'

--5.We need to get some feedback from all of the employees who have sold Harley Davidson Motorcycles. 
--Get a report of the employee first names and emails for all employees who have ever sold a Harley.
SELECT E.FIRSTNAME, E.EMAIL
FROM(SELECT PRODUCTCODE
     FROM PRODUCTS 
     WHERE PRODUCTNAME LIKE '%Harley%') A
JOIN ORDERDETAILS B
ON A.PRODUCTCODE=B.PRODUCTCODE
JOIN ORDERS C
ON B.ORDERNUMBER=C.ORDERNUMBER
JOIN CUSTOMERS D
ON C.CUSTOMERNUMBER=D.CUSTOMERNUMBER
JOIN EMPLOYEES E
ON D.SALESREPEMPLOYEENUMBER=E.EMPLOYEENUMBER
GROUP BY E.FIRSTNAME, E.EMAIL

--6.We want to display information about customers from France and the USA. 
--Show the customer name, the contact first and last name (in the same column), and the country for all of these customers.
SELECT CUSTOMERNAME, CONCAT(CONTACTFIRSTNAME,' ' ,CONTACTLASTNAME) NAME, COUNTRY 
FROM CUSTOMERS
WHERE COUNTRY IN ('France', 'USA')

--7.We want to dig into customer order history. Show each customer name, along with date of their intial order and their most recent order. 
--Call the initial order ‘first_order’ and the last one ‘last_order’. Also include any customers who have never made an order.
SELECT A.CUSTOMERNAME,MIN(B.ORDERDATE) INIDATE, MAX(B.ORDERDATE) LASTDATE
FROM CUSTOMERS A
LEFT JOIN ORDERS B
ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
GROUP BY A.CUSTOMERNAME

--8.Show each office city, and the average number of orders per employee per office (without displaying the individual employee average). 
--For example, say office ABC has 2 employees. Employee #1 was responsible for 2 orders, and employee #2 was responsible for 6 orders. 
--Then your result set should show “ABC” for the first column (city), and “4” for the second column (avg orders per employee per office: (2+6)/2).
SELECT X.CITY, Y.TTL/X.PPL
FROM(SELECT B.CITY, COUNT(1) PPL
     FROM EMPLOYEES A
     JOIN OFFICES B
     ON A.OFFICECODE=B.OFFICECODE
     GROUP BY B.CITY) X
JOIN(SELECT D.CITY, COUNT(1) TTL
     FROM ORDERS A
     JOIN CUSTOMERS B
     ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
     JOIN EMPLOYEES C
     ON B.SALESREPEMPLOYEENUMBER=C.EMPLOYEENUMBER
     JOIN OFFICES D
     ON C.OFFICECODE=D.OFFICECODE
     GROUP BY D.CITY) Y
ON X.CITY=Y.CITY

--9.Show each product line and the number of products in each product line, for all product lines with more than 20 products.
SELECT X.PRODUCTLINE, X.NUM
FROM(SELECT A.PRODUCTLINE, COUNT(1) NUM
     FROM PRODUCTLINES A
     JOIN PRODUCTS B
     ON A.PRODUCTLINE=B.PRODUCTLINE
     GROUP BY A.PRODUCTLINE) X
WHERE X.NUM>20

--10.We want to get an idea of the status of the orders of our customers. 
--Show each customer number, and then the number of orders they have by status type. 
--So you will have a column for customer number, and then one column each for “shipped”, 
--“in process”, “cancelled”, “disputed”, “resolved”, and “on hold”.
SELECT B.CUSTOMERNUMBER
       ,SUM(CASE A.STATUS WHEN 'Shipped' THEN 1 ELSE 0 END) shipped
       ,SUM(CASE A.STATUS WHEN 'In process' THEN 1 ELSE 0 END) in_process
       ,SUM(CASE A.STATUS WHEN 'Cancelled' THEN 1 ELSE 0 END) cancelled
       ,SUM(CASE A.STATUS WHEN 'Disputed' THEN 1 ELSE 0 END) disputed
       ,SUM(CASE A.STATUS WHEN 'Resolved' THEN 1 ELSE 0 END) resolved
       ,SUM(CASE A.STATUS WHEN 'On hold' THEN 1 ELSE 0 END) on_hold
FROM ORDERS A
JOIN CUSTOMERS B
ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
GROUP BY B.CUSTOMERNUMBER

--11.Select the name of the country and the 'Number of cities' for each country , 
--order the results starting with the country that has the biggest number of cities.
SELECT A.NAME, COUNT(B.ID) NUM
FROM COUNTRY A
LEFT JOIN CITY B
ON A.CODE=B.COUNTRYCODE
GROUP BY A.NAME
ORDER BY NUM DESC

--12.We want to make sure the company is taking care of top clients. 
--We need to find our most profitable orders that haven't shipped yet, 
--so that we can give those customers extra attention. 
--Find the 5 biggest orders (largest subtotal) that have not shipped yet. 
--Display in a report the employee name, customer name, order number, order subtotal, 
--and status for those 5 largest subtotals.
SELECT TOP 5 CONCAT(D.FIRSTNAME, ' ', D.LASTNAME)EMPLOYEE
      ,C.CUSTOMERNAME
      ,A.ORDERNUMBER
      ,(B.QUANTITYORDERED*B.PRICEEACH) order_subtotal
      ,A.STATUS
FROM(SELECT ORDERNUMBER, STATUS, CUSTOMERNUMBER 
     FROM ORDERS 
     WHERE STATUS != 'Shipped') A
JOIN ORDERDETAILS B
ON A.ORDERNUMBER=B.ORDERNUMBER
JOIN CUSTOMERS C
ON A.CUSTOMERNUMBER=C.CUSTOMERNUMBER
JOIN EMPLOYEES D
ON C.SALESREPEMPLOYEENUMBER=D.EMPLOYEENUMBER
ORDER BY order_subtotal DESC

--13.Find the average number of days before the required date that shipped orders are shipped. 
--Round to 2 decimal places.
--VERSION1
SELECT CAST(Y.NUM/X.TTL AS DECIMAL(6,2))
FROM(SELECT '' A, CAST(COUNT(1)AS DECIMAL(6,2)) TTL
     FROM ORDERS
     WHERE STATUS='Shipped') X
JOIN(SELECT '' A,CAST(SUM(DATEDIFF(day, requiredDate, shippedDate)) AS DECIMAL(6,2)) NUM
     FROM ORDERS
     WHERE STATUS='Shipped') Y
ON X.A=Y.A
--VERSION2 cast
SELECT CAST(AVG(CAST(DATEDIFF(day, requiredDate, shippedDate)AS DECIMAL(6,2))) AS DECIMAL(6,2)) NUM
FROM ORDERS
WHERE STATUS='Shipped'
--VERSION3 convert (cinvert與cast差別在於convert可以指定格式)
SELECT CONVERT(DECIMAL(6,2), AVG(CONVERT(DECIMAL(6,2),DATEDIFF(day, requiredDate, shippedDate))))  NUM
FROM ORDERS
WHERE STATUS='Shipped'

--14.We want to see a history of orders and payments by customer # 363. Show a list of their customer number, 
--order/payment date, and order/payment amount. So if they made an order on 1/12 and a payment on 1/15, 
--then you would show the 1/12 order on the first row, and the 1/15 payment on the second row. Show their order amounts as negative.
SELECT A.CUSTOMERNUMBER, B.ORDERDATE, SUM(C.QUANTITYORDERED*PRICEEACH*-1) AMOUNT
FROM(SELECT * FROM CUSTOMERS WHERE CUSTOMERNUMBER=363) A
JOIN ORDERS B
ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
JOIN ORDERDETAILS C
ON B.ORDERNUMBER=C.ORDERNUMBER
GROUP BY A.CUSTOMERNUMBER, B.ORDERDATE
UNION
SELECT X.CUSTOMERNUMBER, Y.PAYMENTDATE, Y.AMOUNT
FROM(SELECT * FROM CUSTOMERS WHERE CUSTOMERNUMBER=363) X
JOIN PAYMENTS Y
ON X.CUSTOMERNUMBER=Y.CUSTOMERNUMBER

--15.Show a list of all the countries that customers come from.
SELECT COUNTRY
FROM CUSTOMERS
GROUP BY COUNTRY

--16.We want to see how many customers our employees are working with. 
--Show a list of employee first and last names (same column), along with the number of customers they are working with.
SELECT CONCAT(A.FIRSTNAME, ' ', A.LASTNAME) NAME
      ,COUNT(CUSTOMERNUMBER) NUM
FROM EMPLOYEES A
JOIN CUSTOMERS B
ON A.EMPLOYEENUMBER=B.SALESREPEMPLOYEENUMBER
GROUP BY CONCAT(A.FIRSTNAME, ' ', A.LASTNAME) 

--17.Find a list of invalid employee email addresses (hint: there might not be any).
SELECT EMAIL
FROM EMPLOYEES
WHERE EMAIL NOT LIKE '%@%.%'

--18.We want to see information about our customers by country. 
--Show a list of customer countries, the number of customers from those countries, 
--and the total amount of payments those customers have made.
SELECT X.COUNTRY, X.NUM, Y.TTL
FROM(SELECT COUNTRY, COUNT(CUSTOMERNUMBER) NUM
     FROM CUSTOMERS 
     GROUP BY COUNTRY) X
JOIN(SELECT A.COUNTRY, SUM(B.AMOUNT) TTL
     FROM CUSTOMERS A
     JOIN PAYMENTS B
     ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
     GROUP BY A.COUNTRY) Y
ON X.COUNTRY=Y.COUNTRY

--19.The company needs to see which customers still owe money. 
--Find customers who have a negative balance (amount owed greater than amount paid). 
--Show the customer number and customer name.
--VERSION1
SELECT Q.CUSTOMERNUMBER, Q.CUSTOMERNAME
FROM(SELECT X.CUSTOMERNUMBER, X.CUSTOMERNAME, X.NEG+Y.POS OWE
     FROM(SELECT A.CUSTOMERNUMBER, A.CUSTOMERNAME, SUM(C.QUANTITYORDERED*C.PRICEEACH*-1) NEG
          FROM CUSTOMERS A
          JOIN ORDERS B
          ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
          JOIN ORDERDETAILS C
          ON B.ORDERNUMBER=C.ORDERNUMBER
          GROUP BY A.CUSTOMERNUMBER, A.CUSTOMERNAME) X
     JOIN(SELECT A.CUSTOMERNUMBER, A.CUSTOMERNAME, SUM(B.AMOUNT) POS
          FROM CUSTOMERS A
          JOIN PAYMENTS B
          ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
          GROUP BY A.CUSTOMERNUMBER, A.CUSTOMERNAME) Y
     ON X.CUSTOMERNUMBER=Y.CUSTOMERNUMBER) Q
WHERE Q.OWE<0

--20.The company wants to see which orders have had issues. 
--Grab everything from the orders table where the comments include the word "difficult".
SELECT *
FROM ORDERS
WHERE COMMENTS LIKE '%difficult%'

--21.Corporate wants to see if there is any correlation between customer success and local sales reps. 
--To start, we want you to find which customers work with employees in their home state. 
--Show the customer names and states of those that apply.
SELECT A.CUSTOMERNAME, A.STATE
FROM CUSTOMERS A
JOIN EMPLOYEES B
ON A.SALESREPEMPLOYEENUMBER=B.EMPLOYEENUMBER
JOIN OFFICES C
ON B.OFFICECODE=C.OFFICECODE
WHERE A.STATE=C.STATE

--22.The boss needs to see a list of product vendors, and the number of items they have in stock. 
--Show the vendors with the most items in stock first.
SELECT PRODUCTVENDOR, SUM(QUANTITYINSTOCK) TTL
FROM PRODUCTS
GROUP BY PRODUCTVENDOR
ORDER BY TTL DESC

--23.We want to see a history of orders and payments by customer # 363. 
--Show a list of their customer number, order/payment date, order/payment amount, 
--and a running total of their balance. So if they made an order on 1/12 and a payment on 1/15, 
--then you would show the 1/12 order on the first row, and the 1/15 payment on the second row. 
--Show their order amounts as negative.
SELECT X.CUSTOMERNUMBER, X.ORDERDATE, X.AMOUNT, SUM(X.AMOUNT) OVER(ORDER BY X.ORDERDATE) SUMTTL
FROM(SELECT A.CUSTOMERNUMBER, B.ORDERDATE, SUM(C.QUANTITYORDERED*C.PRICEEACH*-1) AMOUNT 
    FROM(SELECT * FROM CUSTOMERS WHERE CUSTOMERNUMBER=363) A
    JOIN ORDERS B
    ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
    JOIN ORDERDETAILS C
    ON B.ORDERNUMBER=C.ORDERNUMBER
    GROUP BY A.CUSTOMERNUMBER, B.ORDERDATE
    UNION
    SELECT A.CUSTOMERNUMBER, B.PAYMENTDATE, SUM(B.AMOUNT) AMOUNT
    FROM(SELECT * FROM CUSTOMERS WHERE CUSTOMERNUMBER=363) A
    JOIN PAYMENTS B
    ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
    GROUP BY A.CUSTOMERNUMBER, B.PAYMENTDATE) X

--24.Find the product that has been ordered the most. 
--Show the product name, and how many times it has been ordered.
SELECT TOP 1 C.PRODUCTNAME, SUM(B.QUANTITYORDERED) TTL
FROM ORDERS A
JOIN ORDERDETAILS B
ON A.ORDERNUMBER=B.ORDERNUMBER
JOIN PRODUCTS C
ON B.PRODUCTCODE=C.PRODUCTCODE
GROUP BY C.PRODUCTNAME
ORDER BY TTL DESC

--25.Find dates where both orders and payments were made.
SELECT A.PAYMENTDATE
FROM PAYMENTS A
JOIN ORDERS B
ON A.PAYMENTDATE=B.ORDERDATE
GROUP BY A.PAYMENTDATE

--26.Show a list of all transaction dates, and the combined number of orders and payments made on those days.
SELECT X.PAYMENTDATE, COUNT(1)
FROM(SELECT PAYMENTDATE
     FROM PAYMENTS
     UNION ALL
     SELECT ORDERDATE
     FROM ORDERS ) X
GROUP BY X.PAYMENTDATE

--27.Display a percentage of customers who have made orders of more than one product. 
--Please round your answer to 2 decimal places.
SELECT CAST(J.SON/Q.MOM AS DECIMAL(5, 2))
FROM(SELECT '' Y, CAST(COUNT(1) AS DECIMAL(5, 2)) SON
     FROM(SELECT A.CUSTOMERNUMBER, COUNT(C.PRODUCTCODE) NUM
         FROM CUSTOMERS A
         JOIN ORDERS B
         ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
         JOIN ORDERDETAILS C
         ON B.ORDERNUMBER=C.ORDERNUMBER
         GROUP BY A.CUSTOMERNUMBER) X
     WHERE X.NUM >2) J
JOIN(SELECT '' Y , CAST(COUNT(CUSTOMERNUMBER) AS DECIMAL(5, 2)) MOM
     FROM CUSTOMERS) Q
ON J.Y=Q.Y

--28.Find the number of customers that each management-level (not sales reps) employee is responsible for. 
--This includes customers tied directly to the managers, as well as customers tied to employees that report to the managers. 
--Show the employee name (first and last), their job title, and the number of customers they oversee.
SELECT CONCAT(A.FIRSTNAME, ' ', A.LASTNAME) NAME
      ,A.JOBTITLE
      ,COUNT(C.CUSTOMERNUMBER)
FROM (SELECT * FROM EMPLOYEES WHERE JOBTITLE!='Sales Rep') A
LEFT JOIN EMPLOYEES B
ON A.EMPLOYEENUMBER=B.REPORTSTO
JOIN CUSTOMERS C
ON B.EMPLOYEENUMBER=C.SALESREPEMPLOYEENUMBER
GROUP BY CONCAT(A.FIRSTNAME, ' ', A.LASTNAME), A.JOBTITLE

--29.We want a report of employees and orders that are still in the works (not shipped, cancelled, or resolved). 
--Show the employee name (first and last), customer number, order number, and the status of the order.
SELECT CONCAT(C.FIRSTNAME, ' ',C.LASTNAME) NAME, B.CUSTOMERNUMBER, A.ORDERNUMBER, A.STATUS
FROM (SELECT * FROM ORDERS WHERE STATUS NOT IN ('shipped', 'cancelled', 'resolved')) A
LEFT JOIN CUSTOMERS B
ON A.CUSTOMERNUMBER=B.CUSTOMERNUMBER
LEFT JOIN EMPLOYEES C
ON B.SALESREPEMPLOYEENUMBER=C.EMPLOYEENUMBER

--30.Show all order amounts over $60,000. Order them in ascending order.
SELECT SUM(A.PRICEEACH*A.QUANTITYORDERED) AMOUNT
FROM ORDERDETAILS A
GROUP BY A.ORDERNUMBER
HAVING SUM(A.PRICEEACH*A.QUANTITYORDERED) >= 60000
ORDER BY AMOUNT

--31.Show all order numbers for orders consisting of only one product.
SELECT ORDERNUMBER
FROM ORDERDETAILS
GROUP BY ORDERNUMBER
HAVING COUNT(PRODUCTCODE)=1

--32.We want to see what comments our customers are leaving. 
--Show all order comments (leave out the ones where there are no comments).
SELECT COMMENTS
FROM ORDERS
WHERE COMMENTS IS NOT NULL

--33.Show all of the country and countrylanguage information for countries that speak french and have a GNP greater than 10,000.
SELECT *
FROM (SELECT * FROM COUNTRY WHERE GNP>10000) A
JOIN COUNTRYLANGUAGE B
ON A.CODE=B.COUNTRYCODE
WHERE B.LANGUAGE='French'

--34.show the number of countries where English is an official language, and then show the number of countries where English is spoken. 
--Display each result in its own column (2 total).
SELECT J.COUNTA official_English_count, Q.COUNTB total_English_count
FROM(SELECT '' AA, SUM(X.YES) COUNTA
    FROM(SELECT 1 YES
        FROM COUNTRY A
        JOIN COUNTRYLANGUAGE B
        ON A.CODE=B.COUNTRYCODE
        WHERE B.LANGUAGE='English' AND ISOFFICIAL='T') X) J
JOIN(SELECT '' AA, SUM(Y.ENG) COUNTB
    FROM(SELECT 1 ENG
        FROM COUNTRY A
        JOIN COUNTRYLANGUAGE B
        ON A.CODE=B.COUNTRYCODE
        WHERE B.LANGUAGE='English') Y) Q
ON J.AA=Q.AA

--35.we want to see if there is a correlation between population and life expectancy. 
--Show each country's name, population rank (1 being the highest, and on down from there), 
--life expectancy rank (same), and overall score (population rank + life expectancy rank).
SELECT A.NAME, A.POP, A.LIFE, A.POP+A.LIFE AS TTL
FROM(SELECT NAME
           ,RANK() OVER(ORDER BY POPULATION DESC) AS POP
           ,RANK() OVER(ORDER BY LIFEEXPECTANCY DESC) AS LIFE
    FROM COUNTRY) A
ORDER BY TTL

--36.I noticed that the United States doesn't have Thai listed as one of their languages. 
--After looking through census data, it shows that 0.3 % of people in the USA speak Thai at home. 
--So let's add it to the list in our query result. 
--Show all information about the languages spoken in the USA, and add a row to your results including Thai as well.
SELECT *
FROM COUNTRYLANGUAGE
WHERE COUNTRYCODE='USA'
UNION 
SELECT 'USA', 'Thai', 'F', 0.3

--37.show the country name and population for the second most populated country.
SELECT A.NAME, A.POPULATION
FROM(SELECT NAME, POPULATION, RANK() OVER(ORDER BY POPULATION DESC) POP
     FROM COUNTRY) A
WHERE A.POP=2

--38.Show the languages that account for more than 50% of the population in more than 5 countries. 
--Also display the numer of countries for each language that fit this criteria.
SELECT LANGUAGE, COUNT(COUNTRYCODE) NUM
FROM COUNTRYLANGUAGE
WHERE PERCENTAGE>50
GROUP BY LANGUAGE
HAVING COUNT(COUNTRYCODE)>5
