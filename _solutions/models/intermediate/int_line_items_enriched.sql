with line_items as (
    select * from {{ ref('stg_lineitem') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
)

select
    li.order_id,
    li.line_number,
    o.customer_id,
    li.part_id,
    li.supplier_id,
    o.order_date,
    li.quantity,
    li.extended_price,
    li.discount,
    {{ net_amount('li.extended_price', 'li.discount') }} as net_amount
from line_items li
join orders o using (order_id)
