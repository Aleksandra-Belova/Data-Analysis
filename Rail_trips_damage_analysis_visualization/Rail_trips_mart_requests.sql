-- data overview

select * 
from rail_insurance_claims
limit 100

-- creating dictionary for cities and states

drop table if exists city_dict

select distinct dep_city as city
, case 
	when dep_city like '%(%'
	then left(dep_city, position('(' in dep_city)-1)
	else dep_city
end as city_short
, dep_state as state
, case 
	when dep_state like '%A%'
	then 'North'
	when dep_state like '%N%'
	then 'South'
	when dep_state like '%M%'
	then 'East'
	else 'West'
end as region
into city_dict
from rail_insurance_claims
union
select distinct arr_city
, case 
	when arr_city like '%(%'
	then left(arr_city, position('(' in arr_city)-1)
	else arr_city
end as city_short
, arr_state
, case 
	when arr_state like '%A%'
	then 'North'
	when arr_state like '%N%'
	then 'South'
	when arr_state like '%M%'
	then 'East'
	else 'West'
end as region
from rail_insurance_claims
order by city

-- checking results

select * 
from city_dict

select distinct city
from city_dict
-- 62

select distinct dep_city
into dep
from rail_insurance_claims

select distinct arr_city
into arr
from rail_insurance_claims

select dep_city
, arr_city
from dep
full join arr
on dep_city=arr_city
--62 - ok!

-- building mart for rail damage

select row_number() over(order by dep_date) as id
, dep_city
, dep_state
, dep_carrier
, arr_city
, arr_state
, arr_carrier
, dep_state || '-' || arr_state as route_state
, dep_city || '-' || arr_city as route_city
, rail_speed
, rail_car_type
, rail_owner
, rail_load
, dep_date
, arr_date
, arr_date - dep_date as trip_dur
, car_value
, round(damaged::numeric,1) as damaged
, round((damaged*100.0/car_value)::numeric, 1) as damage_per
, weight
, round(fuel_used::numeric,1) as fuel_used
, proper_dest 
, miles
, stops
into rail_mart
from rail_insurance_claims

-- mart overview 

select * 
from rail_mart

-- average damage and car values by states

select distinct dep_state
, avg(damage_per) over (partition by dep_state) as avg_damage_state
, avg(car_value) over (partition by dep_state) as max_car_value
from rail_mart
order by avg_damage_state desc
-- TN has incredibly high percent of damage

-- maximum and average damage by months

select distinct date_part('month', dep_date) as month_ac
, max(damaged) over (partition by date_part('month', dep_date)) as max_damage_monthly
, avg(damaged) over (partition by date_part('month', dep_date)) as avg_damage_monthly
from rail_mart
order by 2 desc
-- may and april have most damage in average and absolute values

-- maximum and average damage by months and by regions

select distinct date_part('month', dep_date) as month_ac
, region
, max(damaged) over (partition by date_part('month', dep_date) order by region) as max_damage_region
, avg(damaged) over (partition by date_part('month', dep_date) order by region) as avg_damage_region
from rail_mart left join city_dict
on dep_city = city
order by month_ac asc, max_damage_region desc
-- in each month south and west region have most damage

-- finding all dep_carriers with average damage, that is more then average value for all data

with cte as(
select *
, avg(damaged) over (partition by dep_carrier) as avg_damage
, avg(damaged) over () as avg_damage_total
from rail_mart)
select distinct dep_carrier, avg_damage, avg_damage_total
from cte
where avg_damage >= avg_damage_total
-- BNSF, CN, NS

-- finding arr_cities with most stops per trip

select distinct arr_city
, round(sum(stops)::numeric) as avg_stops
, count(id) as num_trips
, round(avg(stops)::numeric,1) as avg_num_stops
from rail_mart 
where stops>0 
group by arr_city
order by 4 desc
-- Waycross, Galesburg, Linwood have most stops