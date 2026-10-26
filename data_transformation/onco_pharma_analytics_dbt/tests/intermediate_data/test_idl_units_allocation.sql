{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('idl_ptnt_txn_units') }} 
WHERE (unit_source='PAP' AND (pap_units<>units_dispensed OR sp_units<>0)) 
    OR (unit_source='SP' AND (sp_units<>units_dispensed OR pap_units<>0)) 
    OR unit_source NOT IN ('PAP','SP') OR pap_units+sp_units<>units_dispensed
