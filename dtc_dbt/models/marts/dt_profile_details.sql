{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH source AS (
    SELECT * FROM {{ ref('stg_instagram_profiles') }}
),

unpacked AS (
    SELECT
        instagram_profile_id,
        profile_id,
        loaded_at,
        jsonb_array_elements(data) AS profile_data
    FROM source
),

extracted AS (
    SELECT
        instagram_profile_id,
        profile_id,
        loaded_at,
        profile_data->>'id' AS instagram_id,
        profile_data->'data'->>'id' AS data_id,
        profile_data->'data'->>'url' AS url,
        profile_data->'data'->>'fbid' AS fbid,
        profile_data->'data'->>'private' AS is_private,
        profile_data->'data'->>'fullName' AS full_name,
        profile_data->'data'->>'inputUrl' AS input_url,
        profile_data->'data'->>'username' AS username,
        profile_data->'data'->>'verified' AS is_verified,
        profile_data->'data'->>'biography' AS biography,
        profile_data->'data'->>'hasChannel' AS has_channel,
        profile_data->'data'->>'postsCount' AS posts_count,
        profile_data->'data'->>'externalUrl' AS external_url,
        profile_data->'data'->>'followsCount' AS follows_count,
        profile_data->'data'->>'profilePicUrl' AS profile_pic_url,
        profile_data->'data'->>'followersCount' AS followers_count,
        profile_data->'data'->>'igtvVideoCount' AS igtv_video_count,
        profile_data->'data'->>'joinedRecently' AS joined_recently,
        profile_data->'data'->>'profilePicUrlHD' AS profile_pic_url_hd,
        profile_data->'data'->>'isBusinessAccount' AS is_business_account,
        profile_data->'data'->>'externalUrlShimmed' AS external_url_shimmed,
        profile_data->'data'->>'highlightReelCount' AS highlight_reel_count,
        profile_data->'data'->>'businessCategoryName' AS business_category_name
    FROM unpacked
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['profile_id', 'loaded_at']) }} as id,
        profile_id,
        instagram_profile_id,
        instagram_id,
        data_id,
        url,
        fbid,
        is_private::boolean,
        full_name,
        input_url,
        username,
        is_verified::boolean,
        biography,
        has_channel::boolean,
        posts_count::integer,
        external_url,
        follows_count::integer,
        profile_pic_url,
        followers_count::integer,
        igtv_video_count::integer,
        joined_recently::boolean,
        profile_pic_url_hd,
        is_business_account::boolean,
        external_url_shimmed,
        highlight_reel_count::integer,
        business_category_name,
        loaded_at as created_at
    FROM extracted
)

SELECT * FROM final

{% if is_incremental() %}

  WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})

{% endif %} 