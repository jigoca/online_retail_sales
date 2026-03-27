# Online Retail Sales Analysis
create database ORSA;
use ORSA;

Create table onlineretail(
InvoiceNo int,

StockCode int,

Description text,

Quantity int,

InvoiceDate text,

UnitPrice double,

CustomerID int,

Country text
);

load data local infile '/Users/carlos/Analisis de Datos/proyectos/online_retail_sales/Online Retail Data Set.csv'
into table onlineretail
character set latin1
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;


alter table onlineretail
add column NewInvoiceDate datetime;

set sql_safe_updates = 0;

update onlineretail
set NewInvoiceDate = str_to_date(InvoiceDate, '%d-%m-%Y %H:%i');

alter table onlineretail
drop column InvoiceDate;

alter table onlineretail
rename column NewInvoiceDate to InvoiceDate;


update onlineretail
set StockCode = '11111'
where StockCode = 0;


select count(distinct StockCode) as distinct_stockcode_count
from onlineretail;

select distinct StockCode, Description
from onlineretail;

-- Encontrar los 10 mejores productos en todos los países.
select StockCode, count(StockCode) as count_of_products
from onlineretail
where StockCode is not null
group by StockCode
order by count_of_products desc
limit 10;

-- Encuentra los 10 productos más distintivos por país y clasifícalos del 1 al 10.
delimiter //
create procedure Top10ProductsCountry()
begin
	with RankedProducts as (
    select Country, StockCode,
		row_number() over (partition by Country order by count(*) desc) as ranked
    from onlineretail
    group by Country, StockCode
    )
	select Country, StockCode,ranked
	from RankedProducts
    where ranked <= 10;
end //
delimiter ;

call Top10ProductsCountry();


-- Agrupa los StockCode en base al pais, muestra la suma total de StockCode distintos, por pais, para mostrar la diversidad en cada pais
select Country, count(distinct StockCode) as total_distinct_stocks
from onlineretail
group by Country
order by total_distinct_stocks desc;

select Country, count(StockCode) as total_distinct_stocks
from onlineretail
group by Country
order by total_distinct_stocks;

-- Encontrar los 10 productos menos ordenados entre todos los paises
select StockCode, count(StockCode) as LeastOrderedItems
from onlineretail
where StockCode is not null
group by StockCode
having LeastOrderedItems between 1 and 10
order by LeastOrderedItems asc;

-- Agrupar los productos(StockCode) por cada pais, para encontrar el mercado mas grande
select country, count(StockCode) as total_stocks
from onlineretail
where StockCode is not null
group by Country
order by total_stocks desc;

-- Encontrar los 10 paises con mas clientes
select country, count(CustomerID) as customers
from onlineretail
where CustomerID is not null
group by Country
order by customers desc
limit 10;


select country, customer_count, ranked_customer
from (
	select country, count(CustomerID) as customer_count,
    dense_rank() over (order by count(CustomerID) desc) as ranked_customer
	from onlineretail
	group by Country) as ranked
order by ranked_customer
limit 10;

-- Encontrar los 10 items que son ordenados en mayor cantidad
select StockCode, count(StockCode) as count_of_items, sum(Quantity) as total_quantity
from onlineretail
group by StockCode
order by total_quantity desc
limit 10;

-- Encontrar que dia se genero mas ventas
select dayname(InvoiceDate) as Days, count(InvoiceNo) as count_of_sales
from onlineretail
group by dayname(InvoiceDate)
order by count(StockCode) desc;

-- Encontrar top 10 items unicos ordenados en los fines de semana (Fri, Sat, Sun)
select StockCode, dayname(InvoiceDate) as Days, count(StockCode) as counted
from onlineretail
where dayname(InvoiceDate) in ('Saturday', 'Sunday', 'Friday')
group by StockCode, dayname(InvoiceDate)
order by count(StockCode) desc;

-- Mejorar la visualizacion 
select StockCode, max(Sunday) as Sunday, max(Saturday) as Saturday, max(Friday) as Friday
from (select StockCode,
		sum(case when dayname(InvoiceDate) = 'Friday' then 1 else 0 end) as Friday,
        sum(case when dayname(InvoiceDate) = 'Saturday' then 1 else 0 end) as Saturday,
        sum(case when dayname(InvoiceDate) = 'Sunday' then 1 else 0 end) as Sunday
        from onlineretail
        group by StockCode
) as subquery
group by StockCode
order by (Friday+Saturday+Sunday) desc limit 10;

-- Check out the top 10% of unique items which are most ordered in weekends (Fri, Sat,Sun), group them accordingly with the item stockcode.

SELECT Stockcode, Days, counted
FROM (SELECT count(Stockcode) as counted , DAYNAME(InvoiceDate) AS Days, stockcode,
	NTILE(10) OVER(ORDER BY COUNT(Stockcode) DESC) AS percentile_group
    FROM onlineretail
    WHERE DAYNAME(InvoiceDate) IN ('Saturday', 'Sunday', 'Friday')
    GROUP BY Stockcode, Days) AS subquery
WHERE percentile_group = 1 -- Selecting top 10%
GROUP BY Stockcode, Days
ORDER BY COUNT(Stockcode) DESC;

-- which top 10 items caused highest sales, rank them, where sale = (unitprice x quantity)

Select stockcode, round(SUM((UnitPrice*Quantity)),2) as Sales,
Rank() over (order by SUM((UnitPrice*Quantity)) DESC) as ranked_over_Sales
from onlineretail
group by stockcode
limit 10;

select * from onlineretail;