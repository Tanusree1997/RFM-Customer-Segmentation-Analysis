Create Database automobile_sales;
Use automobile_sales;

SELECT * FROM `auto sales data`;



/* DATA CLEANING */
/*Checking whether the dataset has any null values or not */
Select concat(Order_ID, Quantity, Price, ORDERLINENUMBER, Sales, `Status`, Productline, MSRP, Product_code, Customer_name, Phone_no, 
Addressline1, City, Postal_code, Country, CONTACTLASTNAME, CONTACTFIRSTNAME, orderdate) as concatinated From `auto sales data`
Where concat(Order_ID, Quantity, Price, ORDERLINENUMBER, Sales, `Status`, Productline, MSRP, Product_code, Customer_name, Phone_no, 
Addressline1, City, Postal_code, Country, CONTACTLASTNAME, CONTACTFIRSTNAME, orderdate) is null;
/* No null value is found */



/* DATA ENGINEERING */
/* Changing the data type of date column */
alter table `auto sales data`
add column Orderdate date;

select str_to_date(Order_date, "%d/%c/%Y"), Orderdate
from `auto sales data`;

set SQL_safe_updates=0;

update `auto sales data`
set Orderdate = Str_to_date(Order_date, "%d/%c/%Y");

Alter table `auto sales data`
drop Order_date;


/* RFM ANALYSIS */
/*There are multiple orders done by one customer*/
Select Customer_name, Order_ID, Sales, orderdate,
Count(Order_ID) Over(partition by Customer_name, Order_ID)
From `auto sales data`;

/* Summarization */
Select Customer_name, Order_ID, Round(sum(Sales), 2) as Total_sales, Orderdate 
From  `auto sales data`
Group by Customer_name, Order_ID, Orderdate;

/* Ranking */
With Order_summary as 
	(Select Customer_name, Order_ID, Round(sum(Sales), 2) as Total_sales, Orderdate 
	From  `auto sales data`
	Group by Customer_name, Order_ID, Orderdate)
    
Select t1.Customer_name, 
(select max(orderdate) from order_summary where Customer_name = t1.Customer_name) as max_customer_orderdate,
Datediff("2022-12-30", 
(select max(orderdate) from order_summary where Customer_name = t1.Customer_name)) as DaysSinceLastOrder,
Count(t1.order_id) as Orderspercustomer,
Round(Sum(t1.Total_sales)) as Salespercustomer,
Ntile(3) over(order by Datediff("2022-12-30", 
(select max(orderdate) from order_summary where Customer_name = t1.Customer_name))Desc) as Recency,
Ntile(3) over(order by Count(t1.order_id)) as Frequency,
(Case 
	When Ntile(3) over(order by Round(Sum(t1.Total_sales))) = 1 Then "Low"
    When Ntile(3) over(order by Round(Sum(t1.Total_sales))) = 2 Then "Medium"
    Else "High"
End) as Monetary
From Order_summary t1
Group by Customer_name
Order by 1 asc;

/* The final dataset */
Select r.customer_name, concat(Recency,Frequency,Monetary)  as RFM,
(Case When concat(Recency,Frequency,Monetary) like "33High" Then "Best"
	When concat(Recency,Frequency,Monetary) like "33Medium" Then "Regular"
    When concat(Recency,Frequency,Monetary) like "33Low" Then "Regular"
	When concat(Recency,Frequency,Monetary) like "32Medium" Then "Potential regulars" 
	When concat(Recency,Frequency,Monetary) like "32low" Then "Potential regulars"
    When concat(Recency,Frequency,Monetary) like "22Medium" Then "Potential regulars"
    When concat(Recency,Frequency,Monetary) like "23low" Then "Potential regulars"
    When concat(Recency,Frequency,Monetary) like "23High" Then "Almost Lost"
	When concat(Recency,Frequency,Monetary) like "23Medium" Then "Almost Lost"
    When concat(Recency,Frequency,Monetary) like "13High" Then "Lost"
    When concat(Recency,Frequency,Monetary) like "11Low" Then "Lost Cheap"
	When concat(Recency,Frequency,Monetary) like "11Medium" Then "Lost Cheap"
    When concat(Recency,Frequency,Monetary) like "22low" Then "Lost Cheap"
	When concat(Recency,Frequency,Monetary) like "21low" Then "Lost Cheap"
    When concat(Recency,Frequency,Monetary) like "__High" Then "Occassional Big Spenders"
Else "Not categorised"
End) as segments
From `rfm ranking` as r inner join `auto sales data` as a on r.customer_name= a.customer_name;


