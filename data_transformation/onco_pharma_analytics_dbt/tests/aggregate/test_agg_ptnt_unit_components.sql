{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('agg_ptnt_period_performance') }} 
WHERE COALESCE(total_dispensed_units,0) <> COALESCE(sp_units,0) + COALESCE(pap_units,0) 
    OR COALESCE(total_fills,0) <> COALESCE(sp_fills,0) + COALESCE(pap_fills,0) 
    OR COALESCE(total_refills,0) <> COALESCE(sp_channel_refills,0) + COALESCE(pap_channel_refills,0)
