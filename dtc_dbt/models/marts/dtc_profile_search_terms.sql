{{
    config(
        materialized='incremental',
        unique_key='profile_search_term_id'
    )
}}

WITH source_profiles AS (
    -- Get the profiles that were found from google search
    SELECT
        username,
        search_term_id
    FROM
        {{ ref('google_search_instagram_profiles') }}
),

dtc_profiles AS (
    -- Get the surrogate key for the profile
    SELECT
        id as profile_id,
        username
    FROM
        {{ ref('dtc_profiles')}}
)

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['profile_id', 'search_term_id']) }} as profile_search_term_id,
    dp.profile_id,
    sp.search_term_id
FROM
    source_profiles sp
LEFT JOIN
    dtc_profiles dp ON sp.username = dp.username

{% if is_incremental() %}

  WHERE {{ dbt_utils.generate_surrogate_key(['profile_id', 'search_term_id']) }} NOT IN (SELECT profile_search_term_id FROM {{ this }})

{% endif %} 