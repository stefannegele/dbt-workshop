select *
from {{ ref('fct_line_items') }}
where abs(net_amount - (extended_price * (1 - discount))) > 0.001
