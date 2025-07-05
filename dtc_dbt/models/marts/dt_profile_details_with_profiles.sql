{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH profile_details AS (
    SELECT * FROM {{ ref('dt_profile_details') }}
),

profiles AS (
    SELECT * FROM {{ ref('dtc_profiles') }}
),

joined AS (
    SELECT
        pd.id,
        pd.profile_id,
        pd.instagram_profile_id,
        pd.instagram_id,
        pd.data_id,
        pd.url,
        pd.fbid,
        pd.is_private,
        pd.full_name,
        pd.input_url,
        pd.username,
        pd.is_verified,
        pd.biography,
        pd.has_channel,
        pd.posts_count,
        pd.external_url,
        pd.follows_count,
        pd.profile_pic_url,
        pd.followers_count,
        pd.igtv_video_count,
        pd.joined_recently,
        pd.profile_pic_url_hd,
        pd.is_business_account,
        pd.external_url_shimmed,
        pd.highlight_reel_count,
        pd.business_category_name,
        pd.created_at,
        p.country,
        p.status as profile_status,
        p.created_at as profile_created_at,
        p.updated_at as profile_updated_at
    FROM profile_details pd
    LEFT JOIN profiles p ON pd.profile_id = p.id
)

SELECT * FROM joined

{% if is_incremental() %}

  WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})

{% endif %} 