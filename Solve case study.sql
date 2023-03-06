SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;


---Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select c.market
from dim_customer as c
where region = 'APAC' AND customer = 'Atliq Exclusive'
limit 8;


---What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
--unique_products_2020
--unique_products_2021
--percentage_chg

with year2020 as (
	select count(distinct(product_code)) as UNIQUE_PRODUCT_2020
	from fact_sales_monthly 
	where fiscal_year = '2020'),
year2021 as(
	select count(distinct(product_code)) as UNIQUE_PRODUCT_2021
	from fact_sales_monthly 
	where fiscal_year = '2021')
SELECT
     UNIQUE_PRODUCT_2020,
	 UNIQUE_PRODUCT_2021,
     ROUND((UNIQUE_PRODUCT_2021 - UNIQUE_PRODUCT_2020)*100/UNIQUE_PRODUCT_2020,2) AS percentage_chg
FROM year2020,year2021;

---Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
--2 fields,
--segment
--product_count

select segment, count(distinct(product_code)) as product_counts
from dim_product
group by segment
order by product_counts desc;


---Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
--segment
--product_count_2020
--product_count_2021
--difference

with year2020 as (
select 
	p.segment,
	count(distinct(s.product_code)) as product_count_2020
from 
	dim_product as p
	join fact_sales_monthly as s
	on p.product_code = s.product_code
where 
	fiscal_year = 2020
group by 
    1),
	 
year2021 as (
select 
	p.segment,
	count(distinct(s.product_code)) as product_count_2021
from
	dim_product as p
	join fact_sales_monthly as s
	on p.product_code = s.product_code
where 
	fiscal_year = 2021
group by 
    1)
select
    year2020.segment,
	product_count_2020,
	product_count_2021,
	(product_count_2021 - product_count_2020) as difference
from year2020
join year2021
on year2020.segment = year2021.segment
order by difference desc;

---Get the products that have the highest and lowest manufacturing costs.
--The final output should contain these fields,
--product_code
--product
--manufacturing_cost

select 
     p.product,
	 p.product_code,
	 m.manufacturing_cost
from 
     dim_product as p
     join fact_manufacturing_cost as m
	 on p.product_code = m.product_code
where 
     m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) 
	 OR
     m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

---Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
--The final output contains these fields,
--customer_code
--customer
--average_discount_percentage

select 
     c.customer_code,
	 c.customer,
	 round(avg(d.pre_invoice_discount_pct),2) as avg_pct
from 
     dim_customer as c
	 join fact_pre_invoice_deductions as d
	 on c.customer_code = d.customer_code
where 
     market = 'India' and fiscal_year = '2021'
group by 1,2
order by
     avg_pct desc
Limit 5;


---Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
---This analysis helps to get an idea of low and high-performing months and take strategic decisions.
--The final report contains these columns:
--Month
--Year
--Gross sales Amount

select 
    Extract(Month from  s.date) as month,
	Extract(Year from s.date) as year,
	sum(g.gross_price * s.sold_quantity) as gross_sales_amount
from 
    fact_sales_monthly as s 
	join fact_gross_price as g 
	on s.product_code = g.product_code
	join dim_customer as c 
	on s.customer_code = c.customer_code
where 
    c.customer = 'Atliq Exclusive'
group by 1,2
order by 2;



---In which quarter of 2020, got the maximum total_sold_quantity? 
--The final output contains these fields sorted by the total_sold_quantity,
--Quarter
--total_sold_quantity

select 
      Extract(Quarter from date) as Quarter,
	  sum(sold_quantity) as Total_sold_quantity
from 
      fact_sales_monthly
where fiscal_year = 2020
group by 1
order by Total_sold_quantity desc;


---Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
--The final output contains these fields,
--channel
--gross_sales_mln
--percentage

select 
     c.channel,
	 round(sum(g.gross_price * s.sold_quantity)/1000000,2) as gross_sales
from
     dim_customer as c
	 join fact_sales_monthly as s
	 on c.customer_code = s.customer_code
	 join fact_gross_price as g
	 on g.product_code = s.product_code
where 
     s.fiscal_year = 2021
group by 1
order by gross_sales desc


---Get the Top 3 products in each division that have a hightotal_sold_quantity in the fiscal_year 2021? 
--The final output contains these fields,
--division
--product_code
--product
--total_sold_quantity
--rank_order


WITH CTE AS(
	SELECT 
	    p.division,
	    s.product_code,
	    p.product,
        SUM(s.sold_quantity) AS Total_Sold_Quantity,
	    DENSE_RANK() OVER(PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS Rank_Order
    FROM 
	    dim_product AS p
        JOIN fact_sales_monthly AS s
        ON p.product_code=s.product_code
    WHERE 
	    s.fiscal_year=2021
    GROUP BY 
	    p.division,
	    s.product_code,
	    p.product)
SELECT
    * 
FROM 
    CTE
WHERE 
    Rank_Order<=3;
