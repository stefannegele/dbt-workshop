with source as (
    select * from {{ source('tpch', 'part') }}
),

renamed as (
    select
        p_partkey as part_id,
        p_mfgr    as manufacturer,
        p_brand   as brand,
        p_type    as type
    from source
)

select * from renamed
