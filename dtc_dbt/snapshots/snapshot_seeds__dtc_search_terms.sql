{% snapshot snapshot_seeds__dtc_search_terms %}

{{
    config(
      target_schema='dtc_snapshots',
      strategy='check',
      unique_key='search_term_id',
      check_cols='all',
    )
}}

select * from {{ ref('stg_seeds__dtc_search_terms') }}

{% endsnapshot %} 