select
    part_id,
    manufacturer,
    brand,
    type
from {{ ref('stg_part') }}
