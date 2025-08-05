--Customer Report
--AMA�:Bu rapor temel m��teri �l��mlerini ve davran��lar�n� bir araya getiirr.
--�ne ��kanlar:
/*
1.isim ,ya�,i�lem detaylar� gibi temel alanlar� toplar.
2.m��teri segmentasyonu yap�l�r.
3.M��teri d�zeyindeki �l��mler toplan�r:
   -toplam �ipari�
   -sat�n al�nan toplam miktar
   -toplam �r�nler
4.De�erli KPI:
   -son sipar��ten bu yana ge�en ay
   -ortalama sipari� de�eri
   -ortalama ayl�k harcama
*/

--1)Temel Sorgu:
 
WITH base_query AS (
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
DATEDIFF(year,c.birthdate,GETDATE()) age
FROM gold.fact_sales f
JOIN gold.dim_customers c
ON c.customer_key=f.customer_key
WHERE order_date IS NOT NULL)

,customer_aggregations AS (
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_product,
MAX(order_date) AS last_order_date,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,customer_number,customer_name,age)

SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age<20 THEN 'Under 20'
     WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 40 and 39 THEN '30-39'
	 WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
	 ELSE '50 and Above'
END AS age_group,
CASE WHEN lifespan>=12 AND total_sales>5000 THEN 'VIP'
     WHEN lifespan>=12 AND total_sales<=5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month,last_order_date,GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_product,
last_order_date,
lifespan,
CASE WHEN total_orders=0 then 0
     else total_sales/total_orders
END AS avg_order_value,
CASE WHEN lifespan=0 THEN total_sales
     ELSE total_sales/lifespan
END AS avg_monthly_spend
FROM customer_aggregations
