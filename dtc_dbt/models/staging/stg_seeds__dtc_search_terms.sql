WITH source AS (

    SELECT * FROM {{ ref('dtc_search_terms') }}

),

renamed AS (

    SELECT
        category,
        search_term,
        search_term_en,
        country

    FROM source

), 

with_surrogate_key AS (

    SELECT
        *,
        {{ dbt_utils.generate_surrogate_key(['search_term', 'country']) }} AS search_term_id
    FROM
        renamed

)

SELECT * FROM with_surrogate_key 