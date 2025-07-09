{{
    config(
        materialized='table'
    )
}}

WITH organic_results AS (
    SELECT * FROM {{ ref('stg_google_search_organic_results') }}
),

url_parts AS (
    SELECT
        search_term_id,
        country_code,
        url,
        split_part(url, '?', 1) AS url_without_query,
        regexp_split_to_array(trim(trailing '/' from split_part(url, '?', 1)), '/') AS path_parts
    FROM
        organic_results
),

extracted_usernames AS (
    SELECT
        search_term_id,
        country_code,
        url,
        CASE
            -- e.g. https://www.instagram.com/username/
            WHEN array_length(path_parts, 1) = 4 AND path_parts[4] NOT IN ('p', 'reel', 'tv', 'explore', 'stories', 'directory')
            THEN path_parts[4]
            -- e.g. https://www.instagram.com/username/p/post_id/
            WHEN array_length(path_parts, 1) >= 5 AND path_parts[4] NOT IN ('p', 'reel', 'tv', 'explore', 'stories', 'directory')
            THEN path_parts[4]
            ELSE NULL
        END AS username
    FROM
        url_parts
)

SELECT DISTINCT
    username,
    search_term_id,
    country_code
FROM
    extracted_usernames
WHERE
    username IS NOT NULL 