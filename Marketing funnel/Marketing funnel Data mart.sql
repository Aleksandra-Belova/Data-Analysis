--1. new_marketing_registration

with crm as(
  SELECT 
  COALESCE( d.responsible_unit, l.responsible_unit) AS responsible_unit, 
  COALESCE( d.responsible_user, l.responsible_user) AS responsible_user, 
  l.* EXCEPT( responsible_unit, responsible_user, utm_medium_main, calls, comments, emails, account_type,phone, 
additional_user_id ), 
  d.deal_id, 
  d.date_success AS date_success_deal, 
  d.date_lose AS date_lose_deal, 
  d.stage_id_lose AS  stage_id_lose_deal, 
  IF( l.utm_medium IS NULL, "undefined", l.utm_medium_main) AS utm_medium_main

FROM `leads` l
LEFT JOIN `deals` d 
  ON CAST(l.lead_id AS STRING) = d.lead_id
WHERE
 COALESCE( d.responsible_user, l.responsible_user) NOT IN ("А","Б") 
  AND deleted_lead IS NULL
),

final as (select lead_id
, ext_user_id
, SUBSTR(CAST(DATE_TRUNC(date_registration, MONTH) as string),1,10) AS month_registration
, IF(month_registration is not null, 1, null) AS number_registration
FROM bitrix
LEFT JOIN `registrations` AS reg
ON ext_user_id = user_id
where datetime(date_registration) >= datetime(created_at)
and landing_name like '%certain%')

select * from final

-- 2. new_marketing_account_creation 

with crm as(
  SELECT 
  COALESCE( d.responsible_unit, l.responsible_unit) AS responsible_unit, 
  COALESCE( d.responsible_user, l.responsible_user) AS responsible_user, 
  l.* EXCEPT( responsible_unit, responsible_user, utm_medium_main, calls, comments, emails,account_type,phone, 
additional_user_id ), 
  d.deal_id, 
  d.date_success AS date_success_deal, 
  d.date_lose AS date_lose_deal, 
  d.stage_id_lose AS  stage_id_lose_deal, 
  IF( l.utm_medium IS NULL, "undefined", l.utm_medium_main) AS utm_medium_main

FROM `leads` l
LEFT JOIN `deals` d 
  ON CAST(l.lead_id AS STRING) = d.lead_id
WHERE
 COALESCE( d.responsible_user, l.responsible_user) NOT IN ("А","Б") 
  AND deleted_lead IS NULL
)
SELECT DISTINCT lead_id
, ext_user_id
, SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) AS month_creation
, IF(SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) is not null, 1, null) AS number_creation
FROM crm
LEFT JOIN `accounts` AS ac
ON ext_user_id = user_id
where ad_system  = 'new'
and date(date_created) > date(created_at)
and landing_name like "%certain%"
group by 1,2

--3. new_marketing_payment

with crm as(
  SELECT 
  COALESCE( d.responsible_unit, l.responsible_unit) AS responsible_unit, 
  COALESCE( d.responsible_user, l.responsible_user) AS responsible_user, 
  l.* EXCEPT( responsible_unit, responsible_user, utm_medium_main, calls, comments, emails,account_type,phone, 
additional_user_id ), 
  d.deal_id, 
  d.date_success AS date_success_deal, 
  d.date_lose AS date_lose_deal, 
  d.stage_id_lose AS  stage_id_lose_deal, 
  IF( l.utm_medium IS NULL, "undefined", l.utm_medium_main) AS utm_medium_main

FROM `leads` l
LEFT JOIN `deals` d 
  ON CAST(l.lead_id AS STRING) = d.lead_id
WHERE
 COALESCE( d.responsible_user, l.responsible_user) NOT IN ("А","Б") 
  AND deleted_lead IS NULL
),

account as (SELECT DISTINCT lead_id
, created_at
, ext_user_id
, account_name
, ad_system
, SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) AS month_creation
, IF(SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) is not null, 1, null) AS number_creation
FROM crm
LEFT JOIN `accounts` AS ac
ON ext_user_id = user_id
where ad_system  = 'new'
and date(date_created) >= date(created_at)
and landing_name like "%certain%"
group by 1,2,3,4,5)

select lead_id 
, ext_user_id
, IF(SUM(price_rub)>0, 1, 0) AS fact_payment
, SUBSTR(CAST(DATE_TRUNC(date_payed, MONTH) as string),1,10) AS month_payment
, SUM(price_rub) as sum_payment
FROM account
LEFT JOIN `money` as money
ON ext_user_id = money.user_id 
and account.account_name = money.account_name 
and money.user_id = account.ext_user_id
where ad_system  = 'new'
and value = 'new'
group by 1,2,4

-- 4. new_marketing_profit

with crm as(
  SELECT 
  COALESCE( d.responsible_unit, l.responsible_unit) AS responsible_unit, 
  COALESCE( d.responsible_user, l.responsible_user) AS responsible_user, 
  l.* EXCEPT( responsible_unit, responsible_user, utm_medium_main, calls, comments, emails,account_type,phone, 
additional_user_id ), 
  d.deal_id, 
  d.date_success AS date_success_deal, 
  d.date_lose AS date_lose_deal, 
  d.stage_id_lose AS  stage_id_lose_deal, 
  IF( l.utm_medium IS NULL, "undefined", l.utm_medium_main) AS utm_medium_main

FROM `leads` l
LEFT JOIN `deals` d 
  ON CAST(l.lead_id AS STRING) = d.lead_id
WHERE
 COALESCE( d.responsible_user, l.responsible_user) NOT IN ("А","Б") 
  AND deleted_lead IS NULL
),

account as (SELECT DISTINCT lead_id
, created_at
, ext_user_id
, account_name
, ad_system
, SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) AS month_creation
, IF(SUBSTR(CAST(DATE_TRUNC(min(date_created), MONTH) as string),1,10) is not null, 1, null) AS number_creation
FROM crm
LEFT JOIN `accounts` AS ac
ON ext_user_id = user_id
where ad_system  = 'new'
and date(date_created) >= date(created_at)
and landing_name like "%certain%"
group by 1,2,3,4,5),

payment as (select ext_user_id
, lead_id
, value
, account.account_name
, month_creation
, IF(SUM(price_rub)>0, 1, 0) AS fact_payment
, SUBSTR(CAST(DATE_TRUNC(date_payed, MONTH) as string),1,10) AS month_payment
, SUM(price_rub) as sum_payment
FROM account
LEFT JOIN `money` as money
ON ext_user_id = money.user_id 
and account.account_name = money.account_name 
and money.user_id = account.ext_user_id
where ad_system  = 'new'
and value = 'new'
group by 1,2,3,4,5,7),

SA_profit AS (
SELECT 
  user_id,
  month,
  SUM(price) as SA_PR
FROM `finances.profit`allocation
LEFT JOIN   `finances.categories` categories 
    ON allocation.value = categories.value
WHERE category IN ("Прибыль", "Profit")
  AND unit = 'SubAgency'
  AND allocation.value = "new"
GROUP BY 1,2
),

SS_profit AS (
SELECT 
  user_id,
  month,
  SUM(price) as SS_PR
FROM `finances.profit`allocation
LEFT JOIN   `finances.categories` categories 
    ON allocation.value = categories.value
WHERE category IN ("Прибыль", "Profit")
  AND unit IN ('SelfService', 'Agency')
  AND allocation.value = "new"
GROUP BY 1,2
),

profit_new as( SELECT
      payment.lead_id,
      ext_user_id,
      fact_payment,
      month_payment as month_PR,
      ifnull(SA_profit.SA_PR, 0) + ifnull(SS_profit.SS_PR, 0) AS PR_new
    FROM payment
    LEFT JOIN SA_profit 
      ON payment.ext_user_id = SA_profit.user_id AND substr(payment.month_payment,1,7)=SA_profit.month
    LEFT JOIN SS_profit
      ON payment.ext_user_id = SS_profit.user_id AND substr(payment.month_payment,1,7)=SS_profit.month),

SA_profit_all AS (
SELECT 
  user_id,
  month,
  SUM(price) as SA_PR
FROM `finances.profit`allocation
LEFT JOIN   `finances.categories` categories 
    ON allocation.value = categories.value
WHERE category IN ("Прибыль", "Profit")
  AND unit = 'SubAgency'
GROUP BY 1,2
),

SS_profit_all AS (
SELECT 
  user_id,
  month,
  SUM(price) as SS_PR
FROM `finances.profit`allocation
LEFT JOIN   `finances.categories` categories 
    ON allocation.value = categories.value
WHERE category IN ("Прибыль", "Profit")
  AND unit IN ('SelfService', 'Agency')
GROUP BY 1,2
),

profit_all as (SELECT profit_new.*,
      ifnull(SA_profit_all.SA_PR, 0) + ifnull(SS_profit_all.SS_PR, 0) AS PR_all
    FROM profit_new
    LEFT JOIN SA_profit_all 
      ON profit_new.ext_user_id = SA_profit_all.user_id AND substr(profit_new.month_PR,1,7)=SA_profit_all.month
    LEFT JOIN SS_profit_all
      ON profit_new.ext_user_id = SS_profit_all.user_id AND substr(profit_new.month_PR,1,7)=SS_profit_all.month)

select * from profit_all

-- 5. new_marketing_utm

SELECT DISTINCT
  l.lead_id,
  COALESCE( d.landing_name, l.landing_name) AS landing_name, 
  COALESCE( d.utm_medium,  l.utm_medium) AS utm_medium, 
  COALESCE( d.utm_source, l.utm_source) AS utm_source, 
  COALESCE ( d.utm_campaign, l.utm_campaign) AS utm_campaign,
  IF(  COALESCE( d.utm_medium,  l.utm_medium) IS NULL, "undefined",  COALESCE( l.utm_medium,  d.utm_medium) ) AS utm_medium_main

FROM `leads` l
LEFT JOIN `deals` d 
  ON CAST(l.lead_id AS STRING) = d.lead_id
WHERE
 COALESCE( d.responsible_user, l.responsible_user) NOT IN ("А","Б") 
AND deleted_lead IS NULL