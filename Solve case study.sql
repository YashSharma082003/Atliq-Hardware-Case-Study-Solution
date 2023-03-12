SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;


---Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

Select 
   c.market
From 
   dim_customer as c
Where 
   region = 'APAC' AND customer = 'Atliq Exclusive';


---What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
--unique_products_2020
--unique_products_2021
--percentage_chg

With year2020 as (
	Select 
	   Count(Distinct(product_code)) as UNIQUE_PRODUCT_2020
	From 
	   fact_sales_monthly 
	Where
	   fiscal_year = '2020'),
year2021 as(
	Select 
	   Count(Distinct(product_code)) as UNIQUE_PRODUCT_2021
	From 
	  fact_sales_monthly 
	Where 
	  fiscal_year = '2021')
Select
     UNIQUE_PRODUCT_2020,
	 UNIQUE_PRODUCT_2021,
     Round((UNIQUE_PRODUCT_2021 - UNIQUE_PRODUCT_2020)*100/UNIQUE_PRODUCT_2020,2) AS percentage_chg
From year2020,year2021;

---Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
--2 fields,
--segment
--product_count

Select 
    segment,
	Count(Distinct(product_code)) as product_counts
From dim_product
Group By segment
Order By product_counts desc;


---Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
--segment
--product_count_2020
--product_count_2021
--difference

With year2020 as (
Select 
	p.segment,
	Count(Distinct(s.product_code)) as product_count_2020
From 
	dim_product as p
	Join fact_sales_monthly as s
	On p.product_code = s.product_code
Where 
	fiscal_year = 2020
Group By 
    1),
	 
year2021 as (
Select 
	p.segment,
	Count(Distinct(s.product_code)) as product_count_2021
From
	dim_product as p
	Join fact_sales_monthly as s
	On p.product_code = s.product_code
Where 
	fiscal_year = 2021
Group By 
    1)
Select
    year2020.segment,
	product_count_2020,
	product_count_2021,
	(product_count_2021 - product_count_2020) as difference
From year2020
Join year2021
On year2020.segment = year2021.segment
Order By difference DESC;

---Get the products that have the highest and lowest manufacturing costs.
--The final output should contain these fields,
--product_code
--product
--manufacturing_cost

Select 
     p.product,
	 p.product_code,
	 m.manufacturing_cost
From 
     dim_product as p
     Join fact_manufacturing_cost as m
	 On p.product_code = m.product_code
Where 
     m.manufacturing_cost = (Select Max(manufacturing_cost) From fact_manufacturing_cost) 
	 OR
     m.manufacturing_cost = (Select Min(manufacturing_cost) From fact_manufacturing_cost)
Order By manufacturing_cost DESC;

---Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
--The final output contains these fields,
--customer_code
--customer
--average_discount_percentage

Select 
     c.customer_code,
	 c.customer,
	 Round(Avg(d.pre_invoice_discount_pct),2) as avg_pct
From 
     dim_customer as c
	 Join fact_pre_invoice_deductions as d
	 On c.customer_code = d.customer_code
Where 
     market = 'India' and fiscal_year = '2021'
Group By 1,2
Order By
     avg_pct desc
Limit 5;


---Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
---This analysis helps to get an idea of low and high-performing months and take strategic decisions.
--The final report contains these columns:
--Month
--Year
--Gross sales Amount

Select 
    Extract(Month from  s.date) as month,
	Extract(Year from s.date) as year,
	Sum(g.gross_price * s.sold_quantity) as gross_sales_amount
From 
    fact_sales_monthly as s 
	Join fact_gross_price as g 
	On s.product_code = g.product_code
	Join dim_customer as c 
	On s.customer_code = c.customer_code
Where 
    c.customer = 'Atliq Exclusive'
Group By 1,2
Order By 2;



---In which quarter of 2020, got the maximum total_sold_quantity? 
--The final output contains these fields sorted by the total_sold_quantity,
--Quarter
--total_sold_quantity

Select 
      Extract(Quarter from date) as Quarter,
	  Sum(sold_quantity) as Total_sold_quantity
From 
      fact_sales_monthly
Where fiscal_year = 2020
Group By 1
Order By Total_sold_quantity desc;


---Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
--The final output contains these fields,
--channel
--gross_sales_mln
--percentage

Select 
     c.channel,
	 Round(Sum(g.gross_price * s.sold_quantity)/1000000,2) as gross_sales
From
     dim_customer as c
	 Join fact_sales_monthly as s
	 On c.customer_code = s.customer_code
	 Join fact_gross_price as g
	 On g.product_code = s.product_code
Where 
     s.fiscal_year = 2021
Group By 1
Order By gross_sales desc;


---Get the Top 3 products in each division that have a hightotal_sold_quantity in the fiscal_year 2021? 
--The final output contains these fields,
--division
--product_code
--product
--total_sold_quantity
--rank_order


With CTE AS(
	Select 
	    p.division,
	    s.product_code,
	    p.product,
        Sum(s.sold_quantity) AS Total_Sold_Quantity,
	    Dense_Rank() OVER(Partition By p.division Order By Sum(s.sold_quantity) DESC) AS Rank_Order
    From 
	    dim_product AS p
        JOIN fact_sales_monthly AS s
        ON p.product_code=s.product_code
    Where 
	    s.fiscal_year=2021
    Group By
	    p.division,
	    s.product_code,
	    p.product)
Select
    * 
From
    CTE
Where
    Rank_Order<=3;
