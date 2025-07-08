{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH source AS (
    -- Get the raw profiles from the staging table
    SELECT DISTINCT
        dtc_raw_instagram_profile_id,
        username
    FROM {{ ref('stg_instagram_profiles') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['dtc_raw_instagram_profile_id']) }} as id,
    dtc_raw_instagram_profile_id,
    username,
    'https://www.instagram.com/' || username AS profile_url
FROM
    source

{% if is_incremental() %}

  WHERE dtc_raw_instagram_profile_id NOT IN (SELECT dtc_raw_instagram_profile_id FROM {{ this }})

{% endif %} 