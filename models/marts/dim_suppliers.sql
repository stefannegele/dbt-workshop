select
    supplier_id,
    name,
    nation
from {{ ref('stg_supplier') }}
