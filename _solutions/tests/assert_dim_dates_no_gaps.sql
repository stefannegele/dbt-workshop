select date_id
from {{ ref('dim_dates') }}
qualify date_id != lag(date_id) over (order by date_id) + interval '1 day'
