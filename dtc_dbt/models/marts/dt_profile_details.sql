{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH source AS (
    SELECT * FROM {{ ref('stg_instagram_profiles') }}
),

extracted AS (
    SELECT
        instagram_profile_id,
        profile_id,
        loaded_at,
        data->>'id' AS instagram_id,
        data->>'url' AS url,
        data->>'fbid' AS fbid,
        data->>'private' AS is_private,
        data->>'fullName' AS full_name,
        data->>'inputUrl' AS input_url,
        data->>'username' AS username,
        data->>'verified' AS is_verified,
        data->>'biography' AS biography,
        data->>'hasChannel' AS has_channel,
        data->>'postsCount' AS posts_count,
        data->>'externalUrl' AS external_url,
        data->>'followsCount' AS follows_count,
        data->>'profilePicUrl' AS profile_pic_url,
        data->>'followersCount' AS followers_count,
        data->>'igtvVideoCount' AS igtv_video_count,
        data->>'joinedRecently' AS joined_recently,
        data->>'profilePicUrlHD' AS profile_pic_url_hd,
        data->>'isBusinessAccount' AS is_business_account,
        data->>'externalUrlShimmed' AS external_url_shimmed,
        data->>'highlightReelCount' AS highlight_reel_count,
        data->>'businessCategoryName' AS business_category_name
    FROM source
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['profile_id', 'loaded_at']) }} as id,
        profile_id,
        instagram_profile_id,
        instagram_id,
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