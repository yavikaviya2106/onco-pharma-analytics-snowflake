WITH call AS (
    SELECT * FROM {{ ref('fct_call_activity') }}
),

call_det AS (
    SELECT 
        fct_call_dtl_sk,
        call_detail_id,
        fct_call_act_sk,
        call_id,
        dim_prod_sk,
        product_id       
    FROM {{ ref('fct_call_detail') }}
),

sample_dis AS (
    SELECT
        fct_sample_dis_sk,
        sample_id,
        fct_call_act_sk,
        call_id,
        fct_call_dtl_sk,
        call_detail_id,
        dim_prod_sk,
        product_id,
        sample_quantity
    FROM {{ ref('fct_sample_disbursed') }}
    WHERE UPPER(sample_status) = 'DISBURSED'
)

SELECT

    call.fct_call_act_sk                       AS fct_call_act_sk,

    call.call_id                               AS call_id,
    

    call_det.fct_call_dtl_sk                   AS fct_call_dtl_sk,
    call_det.call_detail_id                    AS call_detail_id,
    call_det.product_id                        AS product_id,
    call_det.dim_prod_sk                       AS dim_prod_sk,

    call.call_date                             AS call_date,

    call.veeva_hcp_id                          AS veeva_hcp_id,
    call.hcp_npi                               AS hcp_npi,
    call.dim_hcp_sk                             AS dim_hcp_sk,

    call.rep_id                                AS rep_id,
    call.dim_rep_sk                             AS dim_rep_sk,

    call.call_type                             AS call_type,
    call.call_status                           AS call_status,
    call.call_outcome                          AS call_outcome,
    call.call_duration_minutes                 AS call_duration_minutes,
    call.call_purpose                          AS call_purpose,
    call.call_channel                          AS call_channel,

    call.is_planned_call                       AS is_planned_call,
    call.is_target_hcp                         AS is_target_hcp,
    call.call_sequence                         AS call_sequence,
    call.key_message_presented                 AS key_message_presented,

    call.sample_drop_flag                      AS sample_drop_flag,
    sample_dis.fct_sample_dis_sk                   AS fct_sample_dis_sk,
    sample_dis.sample_id                           AS sample_id,
    COALESCE(sample_dis.sample_quantity, 0)        AS sample_units,
    call.follow_up_required                    AS follow_up_required,
    call.follow_up_date                        AS follow_up_date,

    call.location_type                         AS location_type,
    call.location_name                         AS location_name,

    call.parent_call_id                        AS parent_call_id,
    call.follow_up_action                      AS follow_up_action,
    call.next_best_action                      AS next_best_action


FROM call

LEFT JOIN call_det
    ON call.call_id = call_det.call_id

LEFT JOIN sample_dis 
    ON call_det.call_id = sample_dis.call_id
        AND call_det.call_detail_id = sample_dis.call_detail_id
        


