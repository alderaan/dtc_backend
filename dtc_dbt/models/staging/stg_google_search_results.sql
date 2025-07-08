WITH source AS (

    SELECT * FROM {{ source('dtc_raw', 'google_search_results') }}

),

renamed AS (

    SELECT
        id as google_search_result_id,
        search_term_id,
        country_code,
        data,
        loaded_at

    FROM source

)

SELECT * FROM renamed 