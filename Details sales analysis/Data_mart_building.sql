-- creating aggregated table with sales

drop table if exists sales_agg

create table sales_agg(
product varchar(400),
dt date,
revenue bigint
)

insert into sales_agg  
select * 
from Sales2018
union all
select * 
from Sales2019
union all
select * 
from Sales2020
union all
select * 
from Sales2021

-- checking the results, 78 k of rows - correct

select count (*) 
from sales_agg

select * 
from sales_agg 

-- checking dates

select distinct dt 
from sales_agg
order by dt

-- deleting unnecessary rows with rubbish data

delete 
from sales_agg
where product like 'диаграммах%'

delete 
from sales_agg
where product like 'итого'

-- 2. Buliding dictionary

drop table if exists group_dic

create table group_dic(
product varchar(400)
, product_short varchar(400)
, product_group varchar(400)
, unit varchar(400)
)

-- product_short - short name without unit
-- product_group - first word in product description
-- unit - product unit

insert into group_dic
select distinct product
, CASE
	when 
		product like '%шт%'
	then 
		left(trim(product), nullif(charindex(', шт', trim(product)),0)-1)
	when 
		product like '%м%'
	then 
		left(trim(product), nullif(charindex(', м', trim(product)),0)-1)
	when 
		product like '%компл%'
	then 
		left(trim(product), nullif(charindex(', компл', trim(product)),0)-1)
	end as product_short
, left(trim(product), nullif(charindex(' ', trim(product)),0)-1) as product_group
, CASE
	when 
		product like '%шт%'
	then 
		'шт'
	when 
		product like '%м%'
	then 
		'м'
	when 
		product like '%компл%'
	then 
		'компл'
	end as unit
from sales_agg

-- cheking the results, 3 k of groups - ok

select count(*) 
from group_dic

select distinct * 
from group_dic
order by product_group

-- 3. Creating data marts

-- calculating total revenue for previous month, using window function

select 
r.*
, lag(rev) over(order by yr) as rev_pm
from (
	select datepart(year,dt) as yr
	, sum(revenue) as rev
	from sales_agg 
	group by datepart(year,dt) 
) as r

-- creating mart for sales
-- calculating revenue for previous month, using window function, 
-- detalizating by products and products group

drop table if exists sales_mart

select row_number() over(order by s.dt, s.product) as id
, s.product
, product_short
, product_group
, unit
, dt
, datepart(year,dt) as year
, datepart(month,dt) as month
, sum(revenue) as revenue_act
, COALESCE(lag(sum(revenue)) over(partition by s.product order by dt),0.0) as revenue_pm
into sales_mart
from sales_agg s
full join group_dic p
on s.product = p.product
group by s.product, product_group, product_short, unit, dt

-- checking results

select * 
from sales_mart
order by id

-- example of abc analysis data mart (2021)

drop table if exists abc_table

select product_group
, sum(revenue_act) as rev_sum
, round(sum(revenue_act)*100.0/sum(sum(revenue_act)) over(),2) as per
into abc_table
from sales_mart
where year(dt) = 2021
group by product_group
order by per desc

drop table if exists abc_table_final

select product_group
, rev_sum
, round(per,0) as revenue_percent
, round(sum(per) over(order by per desc),0) as revenue_accum_percent
, CASE
	WHEN round(sum(per) over(order by per desc),0) < 80
		THEN 'A'
	WHEN round(sum(per) over(order by per desc),0) < 95
		THEN 'B'
	WHEN round(sum(per) over(order by per desc),0) <= 100
		THEN 'С'	
END AS kpi	
into abc_table_final
from abc_table
order by per desc

select * from abc_table_final
