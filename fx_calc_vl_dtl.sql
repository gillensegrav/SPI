create or replace view fmx.fx_calc_vl_dtl
            (fx_calc_vl_dtl_id, fx_org_dtl_id, calc_vl_ref_cd, calc_vl_cat_cd, calc_vl_type_cd, loc_iden,
             eff_start_date, eff_end_date, est_date, stock_iden, maturity_class_cd, life_history_cd, age_class_cd,
             is_broodstock, run_type_cd, origin_cd, mark_class_cd, species_cd, sex_cd, contact_person_iden,
             calc_vl_cmnt, prcl_iden, data_review_status_cd, aprvl_status_cd, meas_vl, precision_type_cd, precision_vl,
             meas_unt_cat_cd, meas_unt_cd, created_date_time, last_updated_date_time)
as
WITH rotatedpeople(stock_id, person1) AS (SELECT ct.stock_id,
                                                 ct.person1
                                          FROM crosstab('
			  select stock_1.stock_id,
           person.first_name || '' '' || person.last_name AS person,
		   MAX(person.first_name || '' '' || person.last_name) AS person2

           FROM spi.stock stock_1
             JOIN spi.stock_data_series stock_data_series_1 ON stock_data_series_1.stock_id = stock_1.stock_id
             JOIN spi.methodology_title_lut ON methodology_title_lut.methodology_title_lut_id = stock_data_series_1.methodology_title_lut_id
             LEFT JOIN spi.annual_data_detail ON annual_data_detail.stock_data_series_id = stock_data_series_1.stock_data_series_id
             JOIN spi.stock_par_assignment ON stock_par_assignment.stock_id = stock_1.stock_id
             JOIN spi.wdfw_region_lut ON wdfw_region_lut.wdfw_region_lut_id = stock_par_assignment.wdfw_region_lut_id
             JOIN spi.person_role_lut ON person_role_lut.person_role_lut_id = stock_par_assignment.person_role_lut_id
             JOIN spi.sasi_stock_par ON sasi_stock_par.par_id = stock_par_assignment.par_id
             JOIN spi.person ON person.person_id = sasi_stock_par.person_id
             JOIN spi.no_abundance_qty_reason_lut ON no_abundance_qty_reason_lut.no_abundance_qty_reason_lut_id = annual_data_detail.no_abundance_qty_reason_lut_id
          WHERE stock_1.active_ind = true AND stock_data_series_1.due_date IS NOT NULL AND person.inactive_ind = false AND person_role_lut.person_role_desc = ''Data provider''
  and person.last_name <> ''Lensegrav'' and person.last_name <> ''Nacey'' and person.last_name <> ''Weyland''
                         GROUP BY stock_1.stock_id,person
  Order by stock_1.stock_id,person
			   '::text) ct(stock_id uuid, person1 text))
SELECT NULL::character varying             AS fx_calc_vl_dtl_id,
       24                                  AS fx_org_dtl_id,
       ad.annual_data_detail_id            AS calc_vl_ref_cd,
       'NE'::text                          AS calc_vl_cat_cd,
       dt.data_type_short_desc             AS calc_vl_type_cd,
       NULL::character varying             AS loc_iden,
       NULL::date                          AS eff_start_date,
       NULL::date                          AS eff_end_date,
       NULL::date                          AS est_date,
       s.stock_id                          AS stock_iden,
       CASE
           WHEN dt.data_type_short_desc::text = 'NOSAIJ'::text THEN 'Mixed'::text
           WHEN dt.data_type_short_desc::text = 'TSAIJ'::text THEN 'Mixed'::text
           WHEN dt.data_type_short_desc::text = 'NOSAEJ'::text THEN 'Adult'::text
           WHEN dt.data_type_short_desc::text = 'TSAEJ'::text THEN 'Adult'::text
           ELSE NULL::text
           END                             AS maturity_class_cd,
       CASE
           WHEN sp.species_code::text = 'ChumSalmon'::text THEN 'OceanType'::text
           WHEN sp.species_code::text = 'PinkSalmon'::text THEN 'OceanType'::text
           ELSE 'StreamType'::text
           END                             AS life_history_cd,
       NULL::character varying             AS age_class_cd,
       CASE
           WHEN dt.data_type_short_desc::text = 'NOBroodStockRemoved'::text THEN 'Yes'::text
           ELSE 'No'::text
           END                             AS is_broodstock,
       sr.sasi_run_desc                    AS run_type_cd,
       pt.production_type_short_desc       AS origin_cd,
       NULL::character varying             AS mark_class_cd,
       CASE
           WHEN sp.species_code::text = 'CK'::text THEN 'ChinookSalmon'::text
           WHEN sp.species_code::text = 'CO'::text THEN 'CohoSalmon'::text
           WHEN sp.species_code::text = 'SH'::text THEN 'SteelheadTrout'::text
           WHEN sp.species_code::text = 'BT'::text THEN 'BullTrout'::text
           WHEN sp.species_code::text = 'CH'::text THEN 'ChumSalmon'::text
           WHEN sp.species_code::text = 'PK'::text THEN 'PinkSalmon'::text
           WHEN sp.species_code::text = 'SO'::text THEN 'SockeyeSalmon'::text
           WHEN sp.species_code::text = 'CU'::text THEN 'CutthroatTrout'::text
           WHEN sp.species_code::text = 'CT'::text THEN 'CCutthroatTrout'::text
           WHEN sp.species_code::text = 'DV'::text THEN 'DollyVarden'::text
           ELSE sp.species_code::text
           END                             AS species_cd,
       NULL::character varying             AS sex_cd,
       rp.person1                          AS contact_person_iden,
       ad.comment_txt                      AS calc_vl_cmnt,
       sds.stock_data_series_id            AS prcl_iden,
       aqs.abundance_qty_status_short_desc AS data_review_status_cd,
       NULL::character varying             AS aprvl_status_cd,
       ad.stock_abundance_qty              AS meas_vl,
       CASE
           WHEN ad.cv_num::numeric > 0::numeric THEN 'CoeffVariant'::character varying
           ELSE NULL::character varying
           END                             AS precision_type_cd,
       CASE
           WHEN ad.cv_num::numeric > 0::numeric THEN ad.cv_num::numeric
           ELSE NULL::numeric
           END                             AS precision_vl,
       ut.unit_type_lut_desc               AS meas_unt_cat_cd,
       NULL::character varying             AS meas_unt_cd,
       ad.create_dt                        AS created_date_time,
       ad.modify_dt                        AS last_updated_date_time
FROM spi.stock s
         JOIN spi.species_lut sp ON s.species_lut_id = sp.species_lut_id
         JOIN spi.sasi_run_lut sr ON s.sasi_run_lut_id = sr.sasi_run_lut_id
         LEFT JOIN spi.stock_report str ON s.stock_id = str.stock_id
         LEFT JOIN spi.stock_data_series sds ON s.stock_id = sds.stock_id
         LEFT JOIN spi.data_type_lut dt ON sds.data_type_lut_id = dt.data_type_lut_id
         LEFT JOIN spi.unit_type_lut ut ON dt.unit_type_lut_id = ut.unit_type_lut_id
         LEFT JOIN spi.production_type_lut pt ON sds.production_type_lut_id = pt.production_type_lut_id
         LEFT JOIN spi.annual_data_detail ad ON sds.stock_data_series_id = ad.stock_data_series_id
         LEFT JOIN spi.abundance_qty_status_lut aqs ON ad.abundance_qty_status_lut_id = aqs.abundance_qty_status_lut_id
         LEFT JOIN rotatedpeople rp ON s.stock_id = rp.stock_id
WHERE s.active_ind = true;