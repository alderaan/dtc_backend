WITH source AS (

    SELECT * FROM {{ ref('stg_google_search_results') }}

),

unpacked AS (

    SELECT
        google_search_result_id,
        search_term_id,
        country_code,
        jsonb_array_elements(data->'organicResults') AS organic_result,
        loaded_at
    FROM
        source
)

SELECT
    google_search_result_id,
    search_term_id,
    country_code,
    organic_result->>'url' AS url,
    organic_result->>'title' AS title,
    organic_result->>'description' AS description,
    loaded_at
FROM
    unpacked
WHERE
    organic_result->>'url' LIKE '%instagram.com%' 