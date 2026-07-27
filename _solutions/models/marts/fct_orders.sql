select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_total,
    agg.line_count
from {{ ref('stg_orders') }} o
join {{ ref('int_order_totals') }} agg using (order_id)
