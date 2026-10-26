{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('int_hcp_engagements') }} 
WHERE total_engagements <> COALESCE(call_engagements,0) + COALESCE(email_engagements,0) + COALESCE(event_engagements,0) 
    OR distinct_channels NOT BETWEEN 0 AND 3 OR (single_channel_engagement_flag=1 AND multi_channel_engagement_flag=1)
