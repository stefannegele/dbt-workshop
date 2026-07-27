with source as (
    select * from {{ source('tpch', 'orders') }}
)
select * from source
