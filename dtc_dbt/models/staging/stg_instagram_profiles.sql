WITH source AS (

    SELECT * FROM {{ source('dtc_raw', 'instagram_profiles') }}

),

renamed AS (

    SELECT
        id as dtc_raw_instagram_profile_id,
        profile_id,
        data,
        loaded_at

    FROM source

)

SELECT * FROM renamed 