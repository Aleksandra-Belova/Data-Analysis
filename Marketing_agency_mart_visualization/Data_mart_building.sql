-- checking data after loading

select * 
from mrk.transfers_to_ad_systems
limit 100

select * 
from mrk.ad_systems_accounts
limit 100

select * 
from mrk.exchange_rates
limit 100

select * 
from mrk.users_registrations
limit 100

-- checkngi what currency there are in data

select distinct target_currency
, base_currency
from mrk.exchange_rates

-- adding price in usd into mart
-- here and below for building marts we will add or duplicate rows, as data is not big (only 0,5 M rows)

drop table if exists mrk.transfers_mart

select t.*
, e.rate 
, u.user_country
, u.utm_medium 
, u.utm_source
, u.utm_campaign 
, u.user_date_registration::date
into mrk.transfers_mart
from mrk.transfers_to_ad_systems as t
left join mrk.exchange_rates as e
on t.date_payed = e.dt
left join mrk.users_registrations as u
on t.user_id = u.user_id

select * from mrk.transfers_mart

insert into mrk.transfers_mart
select user_id
, ad_system
, account_id
, date_payed 
, price/rate as price 
, 'USD' as currency
, rate
, user_country
, utm_medium
, utm_source
, utm_campaign
, user_date_registration
from mrk.transfers_mart

select * 
from mrk.transfers_mart

-- checking results 

select sum(price)
from mrk.transfers_to_ad_systems
-- 80463321925

select sum(price)
from mrk.transfers_mart
where currency = 'RUB'
-- 80463321925

select sum(price)
from mrk.transfers_mart
where currency = 'USD'
-- 80463321925 / 1257262800 = 64 - ok

-- looking for start and end of transactions

select min(date_payed) 
from mrk.transfers_to_ad_systems
-- 2017-01-13

select max(date_payed) 
from mrk.transfers_to_ad_systems
-- 2019-07-16

-- counting churn rate in absolute values for each month

with cte_base as(
select distinct date_part('year', t.date_payed) as date_year
, date_part('month', t.date_payed) as date_month
, date_part('year', t.date_payed)*100+date_part('month', t.date_payed) as date_sup
, count(distinct user_id)*1.0 as base
, lag(count(distinct user_id)) over (
order by date_part('year', t.date_payed)*100+date_part('month', t.date_payed)) as old_base
from mrk.transfers_to_ad_systems as t
group by date_year, date_month)
select *
, base-old_base as churn
, round(coalesce((old_base-base)/old_base*100.0,0.0),2) as churn_rate
from cte_base

-- result is not correct, it is necessary to analyse each user separetely

-- creating calendar with start and end of each month

drop table if exists mrk.calendar

select distinct date_payed
, date_trunc('month', date_payed::TIMESTAMP)::date as sm
, date_trunc('day', date_trunc('month', date_payed::TIMESTAMP) + '1 month'::INTERVAL - '1 day'::INTERVAL)::date as em
into mrk.calendar
from mrk.transfers_to_ad_systems
order by 1

select * from mrk.calendar

-- creating mart with clients and their status for each month
-- adding actual client base with kpi AB

drop table if exists mrk.active_base

select c.sm
, c.em
, t.*
, 'AB' as kpi
into mrk.active_base
from mrk.transfers_to_ad_systems as t
left join mrk.calendar as c 
on t.date_payed = c.date_payed

-- adding past month client base with kpi PB

insert into mrk.active_base
select (sm::TIMESTAMP - '1 month'::interval)::date as sm
, (em::timestamp - '1 month'::interval)::date as em
, user_id
, ad_system
, account_id
, date_payed
, price
, currency
, 'PB' as kpi
from mrk.active_base

-- checking beginning and and of transactions

select min(date_payed) 
from mrk.active_base
-- 2017-01-13 = 2017-01-13 - ok

select max(date_payed) 
from mrk.active_base
-- 2019-07-16 = 2019-07-16 - ok

-- adding churn clients with kpi OT

insert into mrk.active_base
select sm
, em
, user_id
, ad_system
, account_id
, date_payed
, price
, currency
, 'OT' as kpi
from mrk.active_base as a
where kpi='AB'
and not exists (
select 1 
from mrk.active_base as b 
where sm = a.sm 
and user_id = a.user_id
and kpi = 'PB')

-- adding new clients with kpi IN

insert into mrk.active_base
select sm
, em
, user_id
, ad_system
, account_id
, date_payed
, price
, currency
, 'IN' as kpi
from mrk.active_base as a
where kpi='PB'
and not exists (
select 1 
from mrk.active_base as b 
where sm = a.sm 
and user_id = a.user_id
and kpi = 'AB')

select * 
from mrk.active_base

-- creating table with final results of churn rate
-- counting churn rate using each client separately for each month

drop table if exists mrk.churn_rate

with cte_result as(
select distinct sm
, sum(case 
	when kpi ='OT'
	then 1
end) as churn_clients
, sum(case 
	when kpi ='IN'
	then 1
end) as new_clients
, sum(case 
	when kpi ='AB'
	then 1
end) as actual_base
, sum(case 
	when kpi ='PB'
	then 1
end) as past_month_base
from mrk.active_base
group by sm)
select sm, churn_clients, new_clients, actual_base, past_month_base
, round(sum(churn_clients)*100.0/sum(actual_base)*1.0,1) as churn_rate
into mrk.churn_rate
from cte_result
group by sm, churn_clients, new_clients, actual_base, past_month_base

select * 
from mrk.churn_rate