{{
    config(
        materialized='table'
    )
}}

WITH profile_details AS (
    SELECT * FROM {{ ref('profile_details') }}
),

profiles AS (
    SELECT * FROM {{ ref('profiles') }}
),

profile_search_terms AS (
    SELECT * FROM {{ ref('profile_search_terms') }}
),

search_terms AS (
    SELECT * FROM {{ ref('snapshot_search_terms') }} WHERE dbt_valid_to IS NULL
),

gsip AS (
    SELECT * FROM {{ ref('google_search_instagram_profiles') }}
),

latest_profile_details AS (
    -- Find the most recent scrape for each profile
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY username ORDER BY created_at DESC) as rn
    FROM profile_details
),

latest_country AS (
    -- For each profile, get the most recent country_code from google_search_instagram_profiles
    SELECT
        g.username,
        g.country_code,
        ROW_NUMBER() OVER(PARTITION BY g.username ORDER BY g.search_term_id DESC) as rn
    FROM gsip g
),

final AS (
    SELECT
        p.id AS profile_id,
        p.username,
        p.profile_url,
        MAX(lpd.full_name) AS full_name,
        MAX(lpd.biography) AS biography,
        MAX(lpd.followers_count) AS followers_count,
        MAX(lpd.posts_count) AS posts_count,
        BOOL_OR(lpd.is_private) AS is_private,
        BOOL_OR(lpd.is_verified) AS is_verified,
        MAX(lpd.external_url) AS external_url,
        MAX(lpd.created_at) AS last_scraped_at,
        ARRAY_AGG(DISTINCT st.search_term_en) AS search_terms,
        MAX(lc.country_code) AS country
    FROM profiles p
    LEFT JOIN latest_profile_details lpd
        ON p.username = lpd.username AND lpd.rn = 1
    LEFT JOIN profile_search_terms pst ON p.id = pst.profile_id
    LEFT JOIN search_terms st ON pst.search_term_id = st.search_term_id
    LEFT JOIN latest_country lc ON p.username = lc.username AND lc.rn = 1
    GROUP BY p.id, p.username, p.profile_url
)

SELECT * FROM final 