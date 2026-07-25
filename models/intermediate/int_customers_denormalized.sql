select
    c.customer_id,
    c.name,
    c.market_segment,
    n.nation_name,
    r.region_name
from {{ ref('stg_customers') }} c
join {{ ref('stg_nation') }} n using (nation_id)
join {{ ref('stg_region') }} r using (region_id)
