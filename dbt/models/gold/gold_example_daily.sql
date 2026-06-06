{{
  config(
    materialized = 'table',
    engine       = 'SummingMergeTree()',
    order_by     = ['event_date', 'source_system'],
  )
}}

SELECT
    toDate(extracted_at)    AS event_date,
    source_system,
    count(*)                AS total_records,
    now()                   AS refreshed_at
FROM {{ ref('silver_example') }}
GROUP BY
    event_date,
    source_system
ORDER BY
    event_date DESC,
    source_system
