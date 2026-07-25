with source as (
    select * from {{ source('tpch', 'customer') }}
),

renamed as (
    select
        c_custkey    as customer_id,
        c_name       as name,
        c_mktsegment as market_segment,
        c_nationkey  as nation_id
    from source
)

select
    customer_id,
    name,
    trim(upper(market_segment)) as market_segment,
    nation_id
from renamed
