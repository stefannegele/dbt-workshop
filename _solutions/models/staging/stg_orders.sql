with source as (
    select * from {{ source('tpch', 'orders') }}
),

renamed as (
    select
        o_orderkey    as order_id,
        o_custkey     as customer_id,
        o_orderstatus as order_status,
        o_totalprice  as order_total,
        o_orderdate   as order_date
    from source
),

cleaned as (
    select
        order_id,
        customer_id,
        trim(upper(order_status)) as order_status,
        coalesce(order_total, 0)  as order_total,
        order_date
    from renamed
)

select
    order_id,
    customer_id,
    case order_status
        when 'O' then 'open'
        when 'F' then 'fulfilled'
        when 'P' then 'processing'
        else order_status
    end as order_status,
    order_total,
    order_date
from cleaned
