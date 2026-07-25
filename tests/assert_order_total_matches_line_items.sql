with line_charges as (
    -- order_total (TPC-H o_totalprice) is tax-inclusive; net_amount deliberately isn't
    -- (Part 3). Reconcile against the tax-inclusive `charge` formula instead:
    -- extended_price * (1 - discount) * (1 + tax).
    select
        order_id,
        sum(extended_price * (1 - discount) * (1 + tax)) as computed_total
    from {{ ref('stg_lineitem') }}
    group by order_id
)
select
    o.order_id,
    o.order_total,
    lc.computed_total,
    abs(o.order_total - lc.computed_total) as diff
from {{ ref('fct_orders') }} o
join line_charges lc using (order_id)
-- Tolerance above observed floating-point rounding noise from summing several lines
-- per order (~$0.11 max across 1.5M orders) — real mismatches (e.g. a missing tax
-- factor) are 3-8% of order value, ~1000x larger than this noise floor.
where abs(o.order_total - lc.computed_total) > 0.20
