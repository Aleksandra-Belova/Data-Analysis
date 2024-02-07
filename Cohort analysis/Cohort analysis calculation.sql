with base AS
(
    SELECT 
        user_id,
        period as month, 
        LEFT(CAST(DATE_TRUNC(date_activation, MONTH) AS STRING),7) AS month_activation, 
        unit, 
        SUM(price_rub) AS revenue
    FROM `money`
    WHERE DATE(date_activation) >= '2019-01-01'
    GROUP BY 1,2,3,4
    ORDER BY 1,2   
),

dates as 
(
    SELECT GENERATE_DATE_ARRAY('2019-01-01',  current_date(), INTERVAL 1 MONTH) AS month_financial
        ),

crj as 
(

    SELECT *
    FROM (
        SELECT 
        DISTINCT user_id, 
        month_activation, 
        unit
        FROM base) base
    CROSS JOIN dates
    WHERE base.month_activation <= dates.month_financial),

final AS
(
    SELECT crj.*, base.revenue
    FROM crj
    LEFT JOIN base
        ON base.month = crj.month_financial AND base.user_id = crj.user_id AND base.unit = crj.unit AND base.month_activation = crj.month_activation
)

select final.*,
DATE_DIFF(CAST(CONCAT(month_financial, '-01') AS DATE), CAST(CONCAT(month_activation, '-01') AS DATE), MONTH) AS month_cohort_num 
from final
order by user_id, month_financial