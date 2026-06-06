{{
  config(
    materialized         = 'incremental',
    engine               = 'ReplacingMergeTree()',
    order_by             = ['id'],
    unique_key           = 'id',
    incremental_strategy = 'delete+insert',
  )
}}

WITH source AS (
    SELECT * FROM {{ ref('bronze_example') }}
),

cleaned AS (
    SELECT
        id,
        -- Normalize / cast fields here
        trim(raw_data)                          AS data_cleaned,
        lower(source_system)                    AS source_system,
        toDateTime(_airbyte_extracted_at)       AS extracted_at,
        now()                                   AS processed_at
    FROM source
    WHERE id IS NOT NULL
      AND raw_data IS NOT NULL
)

SELECT * FROM cleaned

{% if is_incremental() %}
WHERE extracted_at > (
    SELECT max(extracted_at) FROM {{ this }}
)
{% endif %}
