{{
    config(
        materialized='incremental',
        unique_key='username'
    )
}}

WITH extracted_profiles AS (
    SELECT DISTINCT
        username
    FROM {{ ref('google_search_instagram_profiles') }}
)

SELECT
    username,
    'th' as country,
    'pending_review'::public.dtc_profile_status as status,
    now() as created_at,
    now() as updated_at
FROM
    extracted_profiles

{% if is_incremental() %}

  WHERE username NOT IN (SELECT username FROM {{ this }})

{% endif %} 