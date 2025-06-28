{{
    config(
        materialized='incremental',
        unique_key=['profile_id', 'keyword_id']
    )
}}

{% set profiles_relation = ref('dtc_profiles') %}

WITH source_profiles AS (
    SELECT
        username,
        keyword_id
    FROM {{ ref('google_search_instagram_profiles') }}
),

final_profiles AS (
    SELECT
        id as profile_id,
        username
    FROM {{ target.schema }}.dtc_profiles
)

SELECT
    fp.profile_id,
    sp.keyword_id,
    now() as created_at
FROM
    source_profiles sp
JOIN
    final_profiles fp ON sp.username = fp.username

{% if is_incremental() %}

  WHERE (fp.profile_id, sp.keyword_id) NOT IN (SELECT profile_id, keyword_id FROM {{ this }})

{% endif %} 