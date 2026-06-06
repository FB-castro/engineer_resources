{{
  config(
    materialized  = 'incremental',
    engine        = 'ReplacingMergeTree()',
    order_by      = ['id'],
    unique_key    = 'id',
    incremental_strategy = 'append',
  )
}}

SELECT
    id,
    raw_data,
    source_system,
    _airbyte_extracted_at,
    now()                           AS _ingested_at
FROM {{ source('airbyte_raw', 'example_table') }}

{% if is_incremental() %}
WHERE _airbyte_extracted_at > (
    SELECT max(_airbyte_extracted_at) FROM {{ this }}
)
{% endif %}
