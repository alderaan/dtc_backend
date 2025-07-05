{% snapshot snapshot_seeds__dtc_keywords %}

{{
    config(
      target_schema='dtc_snapshots',
      strategy='check',
      unique_key='keyword_id',
      check_cols='all',
    )
}}

select * from {{ ref('stg_seeds__dtc_keywords') }}

{% endsnapshot %} 