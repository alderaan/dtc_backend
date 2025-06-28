{{
    config(
        materialized='incremental',
        unique_key='profile_keyword_id'
    )
}}

WITH source_profiles AS (
    SELECT
        username,
        keyword_id
    FROM {{ ref('google_search_instagram_profiles') }}
),

dtc_profiles AS (
    SELECT
        id,
        username
    FROM {{ ref('dtc_profiles') }}
),

profile_keywords AS (
    SELECT
        dp.id as profile_id,
        sp.keyword_id
    FROM source_profiles sp
    JOIN dtc_profiles dp ON sp.username = dp.username
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['profile_id', 'keyword_id']) }} as profile_keyword_id,
    profile_id,
    keyword_id,
    now() as created_at
FROM profile_keywords

{% if is_incremental() %}

  WHERE {{ dbt_utils.generate_surrogate_key(['profile_id', 'keyword_id']) }} NOT IN (SELECT profile_keyword_id FROM {{ this }})

{% endif %} 