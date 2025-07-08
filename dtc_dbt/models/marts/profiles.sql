{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH extracted_profiles AS (
    SELECT DISTINCT
        username
    FROM {{ ref('google_search_instagram_profiles') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['username']) }} as id,
    username,
    'https://www.instagram.com/' || username AS profile_url
FROM
    extracted_profiles

{% if is_incremental() %}

  WHERE username NOT IN (SELECT username FROM {{ this }})

{% endif %} 