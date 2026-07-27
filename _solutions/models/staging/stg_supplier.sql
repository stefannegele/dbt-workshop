with source as (
    select * from {{ source('tpch', 'supplier') }}
),

renamed as (
    -- "nation" stays the raw nation key here (not resolved to a name) to keep
    -- this dimension slim/1:1, per the workshop's design for dim_suppliers.
    select
        s_suppkey   as supplier_id,
        s_name      as name,
        s_nationkey as nation
    from source
)

select * from renamed
