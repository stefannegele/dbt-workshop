with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('1992-01-01')",
        end_date="to_date('1999-01-01')"
    ) }}
)

select
    date_day          as date_id,
    year(date_day)    as year,
    quarter(date_day) as quarter,
    month(date_day)   as month
from spine
