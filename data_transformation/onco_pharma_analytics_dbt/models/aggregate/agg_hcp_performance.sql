WITH keys AS (
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_calls') }}
    UNION
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_emails') }}
    UNION
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_engagements') }}
    UNION
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_med_events') }}
    UNION
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_rx_metrics') }}
    UNION
    SELECT dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('int_hcp_units') }}
),

calls AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        total_calls, f2f_calls, virtual_calls, phone_calls,
        sample_dropped_calls, sample_units
    FROM {{ ref('int_hcp_calls') }}
),

emails AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        total_emails_sent, emails_delivered, emails_opened, emails_clicked
    FROM {{ ref('int_hcp_emails') }}
),

engagement AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        total_engagements, call_engagements, email_engagements, event_engagements,
        distinct_channels, single_channel_engagement_flag, multi_channel_engagement_flag,
        first_engagement_date, last_engagement_date, days_since_last_engagement
    FROM {{ ref('int_hcp_engagements') }}
),

med_events AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        events_invited, events_attended, attended_as_speaker, attended_as_attendee
    FROM {{ ref('int_hcp_med_events') }}
),

rx AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        first_rx_weekend_date, last_rx_weekend_date,
        writer_flag, new_writer_flag,
        trx, nrx, nbrx, refill_rx,
        trx_units, nrx_units, nbrx_units,
        market_trx, market_nrx
    FROM {{ ref('int_hcp_rx_metrics') }}
),

units AS (
    SELECT
        dim_hcp_sk, dim_prod_sk, product_id, dim_terr_sk, territory_id, bucket_type, bucket_name,bucket_start_date,bucket_end_date,
        pap_units, sp_units
    FROM {{ ref('int_hcp_units') }}
)

SELECT
    -- grain keys
    k.dim_hcp_sk                                              AS dim_hcp_sk,
    k.dim_prod_sk                                             AS dim_prod_sk,
    k.product_id                                              AS product_id,
    k.dim_terr_sk                                             AS dim_terr_sk,
    k.territory_id                                            AS territory_id,
    k.bucket_type                                             AS bucket_type,
    k.bucket_name                                             AS bucket_name,
    k.bucket_start_date                                       AS bucket_start_date,
    k.bucket_end_date                                         AS bucket_end_date,

    -- calls
    COALESCE(c.total_calls, 0)                                AS total_calls,
    COALESCE(c.f2f_calls, 0)                                  AS f2f_calls,
    COALESCE(c.virtual_calls, 0)                              AS virtual_calls,
    COALESCE(c.phone_calls, 0)                                AS phone_calls,
    COALESCE(c.f2f_calls, 0)
        + COALESCE(c.virtual_calls, 0)
        + COALESCE(c.phone_calls, 0)                          AS completed_calls,
    (COALESCE(c.f2f_calls, 0)
        + COALESCE(c.virtual_calls, 0)
        + COALESCE(c.phone_calls, 0) > 0)                     AS call_reached_flag,
    COALESCE(c.sample_dropped_calls, 0)                       AS sample_dropped_calls,
    COALESCE(c.sample_units, 0)                               AS sample_units,

    -- emails
    COALESCE(e.total_emails_sent, 0)                          AS total_emails_sent,
    COALESCE(e.emails_delivered, 0)                           AS emails_delivered,
    COALESCE(e.emails_opened, 0)                              AS emails_opened,
    COALESCE(e.emails_clicked, 0)                             AS emails_clicked,

    -- omnichannel engagement
    COALESCE(g.total_engagements, 0)                          AS total_engagements,
    COALESCE(g.call_engagements, 0)                           AS call_engagements,
    COALESCE(g.email_engagements, 0)                          AS email_engagements,
    COALESCE(g.event_engagements, 0)                          AS event_engagements,
    COALESCE(g.distinct_channels, 0)                          AS distinct_channels,
    COALESCE(g.single_channel_engagement_flag, 0)             AS single_channel_engagement_flag,
    COALESCE(g.multi_channel_engagement_flag, 0)              AS multi_channel_engagement_flag,
    g.first_engagement_date                                   AS first_engagement_date,
    g.last_engagement_date                                    AS last_engagement_date,
    g.days_since_last_engagement                              AS days_since_last_engagement,

    -- medical events
    COALESCE(m.events_invited, 0)                             AS events_invited,
    COALESCE(m.events_attended, 0)                            AS events_attended,
    COALESCE(m.attended_as_speaker, 0)                        AS attended_as_speaker,
    COALESCE(m.attended_as_attendee, 0)                       AS attended_as_attendee,

    -- Rx
    r.first_rx_weekend_date                                   AS first_rx_weekend_date,
    r.last_rx_weekend_date                                    AS last_rx_weekend_date,
    COALESCE(r.writer_flag, FALSE)                            AS writer_flag,
    COALESCE(r.new_writer_flag, FALSE)                        AS new_writer_flag,
    COALESCE(r.trx, 0)                                        AS trx,
    COALESCE(r.nrx, 0)                                        AS nrx,
    COALESCE(r.nbrx, 0)                                       AS nbrx,
    COALESCE(r.refill_rx, 0)                                  AS refill_rx,
    COALESCE(r.trx_units, 0)                                  AS trx_units,
    COALESCE(r.nrx_units, 0)                                  AS nrx_units,
    COALESCE(r.nbrx_units, 0)                                 AS nbrx_units,
    COALESCE(r.market_trx, 0)                                 AS market_trx,
    COALESCE(r.market_nrx, 0)                                 AS market_nrx,
    COALESCE(r.trx, 0) / NULLIF(r.market_trx, 0)       AS trx_market_share,
    COALESCE(r.nrx, 0) / NULLIF(r.market_nrx, 0)       AS nrx_market_share,

    -- patient units
    COALESCE(u.pap_units, 0)                                  AS pap_units,
    COALESCE(u.sp_units, 0)                                   AS sp_units

FROM keys k

LEFT JOIN calls c
    ON  k.dim_hcp_sk  = c.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM c.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM c.dim_terr_sk
    AND k.bucket_type = c.bucket_type
    AND k.bucket_name = c.bucket_name
    AND k.bucket_start_date = c.bucket_start_date
    AND k.bucket_end_date = c.bucket_end_date

LEFT JOIN emails e
    ON  k.dim_hcp_sk  = e.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM e.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM e.dim_terr_sk
    AND k.bucket_type = e.bucket_type
    AND k.bucket_name = e.bucket_name
    AND k.bucket_start_date = e.bucket_start_date
    AND k.bucket_end_date = e.bucket_end_date

LEFT JOIN engagement g
    ON  k.dim_hcp_sk  = g.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM g.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM g.dim_terr_sk
    AND k.bucket_type = g.bucket_type
    AND k.bucket_name = g.bucket_name
    AND k.bucket_start_date = g.bucket_start_date
    AND k.bucket_end_date = g.bucket_end_date

LEFT JOIN med_events m
    ON  k.dim_hcp_sk  = m.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM m.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM m.dim_terr_sk
    AND k.bucket_type = m.bucket_type
    AND k.bucket_name = m.bucket_name
    AND k.bucket_start_date = m.bucket_start_date
    AND k.bucket_end_date = m.bucket_end_date

LEFT JOIN rx r
    ON  k.dim_hcp_sk  = r.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM r.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM r.dim_terr_sk
    AND k.bucket_type = r.bucket_type
    AND k.bucket_name = r.bucket_name
    AND k.bucket_start_date = r.bucket_start_date
    AND k.bucket_end_date = r.bucket_end_date

LEFT JOIN units u
    ON  k.dim_hcp_sk  = u.dim_hcp_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM u.dim_prod_sk
    AND k.dim_terr_sk IS NOT DISTINCT FROM u.dim_terr_sk
    AND k.bucket_type = u.bucket_type
    AND k.bucket_name = u.bucket_name
    AND k.bucket_start_date = u.bucket_start_date
    AND k.bucket_end_date = u.bucket_end_date