{% snapshot snapshot_search_terms %}

{{
    config(
      target_schema='dtc_snapshots',
      strategy='check',
      unique_key='search_term_id',
      check_cols='all',
    )
}}

select 
    *,
    {{ dbt_utils.generate_surrogate_key(['search_term', 'country']) }} AS search_term_id
from {{ ref('search_terms') }}

{% endsnapshot %} 