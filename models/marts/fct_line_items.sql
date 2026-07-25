select
    order_id,
    line_number,
    customer_id,
    part_id,
    supplier_id,
    order_date,
    quantity,
    extended_price,
    discount,
    net_amount
from {{ ref('int_line_items_enriched') }}
