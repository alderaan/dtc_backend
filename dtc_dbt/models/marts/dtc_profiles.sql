{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH extracted_profiles AS (
    SELECT DISTINCT
        username,
        country_code
    FROM {{ ref('google_search_instagram_profiles') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['username']) }} as id,
    username,
    country_code as country,
    'pending_review'::dtc.dtc_profile_status as status,
    now() as created_at,
    now() as updated_at
FROM
    extracted_profiles

{% if is_incremental() %}

  WHERE username NOT IN (SELECT username FROM {{ this }})

{% endif %} 