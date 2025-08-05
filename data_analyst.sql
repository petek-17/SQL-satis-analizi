
--Change Over Time Analytics

--y�llara g�re toplam sat��,m��teri say�s� 
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quanit
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date),MONTH(order_date)

SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quanit
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)

SELECT 
DATETRUNC(year,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quanit
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
ORDER BY DATETRUNC(year,order_date)

--kendi format�m�z� da olu�turabiliriz.
SELECT 
FORMAT(order_date,'yyy-MMM') AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quanit
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyy-MMM') 
ORDER BY FORMAT(order_date,'yyy-MMM') 



--cumulative analysis:i�imizin zaman i�inde nas�l b�y�d���n� anlamak i�in �nemli bir tekniktir.
--ayl�k toplam sat��lar� hesapla
--zaman i�indeki toplam sat��lar� hesapla
SELECT 
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM
(
SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
) t


SELECT 
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) AS moving_avg_price
FROM
(
SELECT 
DATETRUNC(year,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
) t



--performance analytics
WITH yeraly_product_sales AS (
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
)
SELECT order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) avg_sales,
current_sales-AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales-AVG(current_sales) OVER(PARTITION BY product_name) >0 THEN 'Above Avg'
     WHEN current_sales-AVG(current_sales) OVER(PARTITION BY product_name) <0 THEN 'Below Avg'
	 ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) py_sales,
current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) >0 THEN 'Increase'
     WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) <0 THEN 'Decrease'
	 ELSE 'No Change'
END py_change
FROM yeraly_product_sales
ORDER BY product_name,order_year


--part-to-whole
--hangi kategori genel sat��lara en �ok katk�da bulunuyor
WITH category_sales AS(
SELECT 
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key=f.product_key
GROUP BY category)

SELECT 
category,
total_sales,
SUM(total_sales) OVER() overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER())*100,2),'%') AS percentag_of_total
FROM category_sales
ORDER BY total_sales DESC


--Data Segmentation
 --�r�n� maliyet aral���na g�re b�l�mlere ay�r�n 
 --ve para �r�n�n�n her bir b�l�me nas�l d��t���n� say�n
 WITH product_segments AS(
 SELECT 
 product_key,
 product_name,
 cost,
 CASE WHEN cost<100 THEN 'Below 100'
      WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	  WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	  ELSE 'Above 1000'
END cost_range
 FROM gold.dim_products)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP  BY cost_range
ORDER BY total_products DESC


--M��terileri harcama davran��lar�na g�re �� segmente ay�r�n
--vip: en az 12 ayl�k ge�mi�i olan ve 5000'den fazla harcama yapan m��teriler
--regular:en az 12 ayl�k ge�mi�i olan ancak 5000 veya daha az harcama yapan m��teri
--12 aydan az kullan�m �mr�ne sahip m��teri
--ve her gruptaki toplam m��teri say�s�n� bulun
WITH customer_spending AS(
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
FROM gold.fact_sales f
JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
GROUP BY c.customer_key)

SELECT 
customer_segment,
COUNT(customer_key) as total_customers
FROM(
 SELECT
 customer_key,
 CASE WHEN lifespan>=12 AND total_spending>5000 THEN 'VIP'
      WHEN lifespan>=12 AND total_spending<=5000 THEN 'Regular'
	  ELSE 'New'
 END customer_segment
 FROM customer_spending) t
GROUP BY customer_segment
ORDER BY total_customers DESC