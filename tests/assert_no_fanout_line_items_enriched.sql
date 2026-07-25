select
    (select count(*) from {{ ref('stg_lineitem') }})            as source_rows,
    (select count(*) from {{ ref('int_line_items_enriched') }}) as enriched_rows
having source_rows != enriched_rows
