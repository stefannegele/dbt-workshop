select
    order_id,
    count(*)        as line_count,
    sum(net_amount) as order_net_total
from {{ ref('int_line_items_enriched') }}
group by order_id
