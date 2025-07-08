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

latest_profile_details AS (
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY dtc_raw_instagram_profile_id ORDER BY created_at DESC) as rn
    FROM profile_details
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
        ARRAY_AGG(st.search_term) AS search_terms
    FROM profiles p
    LEFT JOIN latest_profile_details lpd
        ON p.dtc_raw_instagram_profile_id = lpd.dtc_raw_instagram_profile_id AND lpd.rn = 1
    LEFT JOIN profile_search_terms pst ON p.id = pst.profile_id
    LEFT JOIN search_terms st ON pst.search_term_id = st.search_term_id
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11
)

SELECT * FROM final 