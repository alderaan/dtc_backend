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
        lpd.full_name,
        lpd.biography,
        lpd.followers_count,
        lpd.posts_count,
        lpd.is_private,
        lpd.is_verified,
        lpd.external_url,
        lpd.created_at AS last_scraped_at,
        ARRAY_AGG(DISTINCT st.search_term_en) AS search_terms,
        lc.country_code AS country
    FROM profiles p
    LEFT JOIN latest_profile_details lpd
        ON p.username = lpd.username AND lpd.rn = 1
    LEFT JOIN profile_search_terms pst ON p.id = pst.profile_id
    LEFT JOIN search_terms st ON pst.search_term_id = st.search_term_id
    LEFT JOIN latest_country lc ON p.username = lc.username AND lc.rn = 1
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
)

SELECT * FROM final 