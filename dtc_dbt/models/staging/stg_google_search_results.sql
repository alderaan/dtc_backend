WITH source AS (

    SELECT * FROM {{ source('dtc', 'dtc_raw_google_search_results') }}

),

renamed AS (

    SELECT
        id as google_search_result_id,
        keyword_id,
        country_code,
        data,
        loaded_at

    FROM source

)

SELECT * FROM renamed 