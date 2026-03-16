DROP PROCEDURE IF EXISTS get_etl_schema $$
CREATE PROCEDURE get_etl_schema(OUT etl_schema VARCHAR(200))
BEGIN
    DECLARE current_schema VARCHAR(200);
    DECLARE tenant_suffix VARCHAR(100);

    SET current_schema = DATABASE();
    IF current_schema IS NULL OR LEFT(current_schema, 8) <> 'openmrs_' THEN
        SET etl_schema = 'kenyaemr_etl';
ELSE
        SET tenant_suffix = SUBSTRING(current_schema, 9);
        IF tenant_suffix IS NULL OR tenant_suffix = '' THEN
            SET etl_schema = 'kenyaemr_etl';
ELSE
            SET etl_schema = CONCAT('kenyaemr_etl_', tenant_suffix);
END IF;
END IF;
END $$
DROP PROCEDURE IF EXISTS sp_populate_etl_crossborder_screening $$
CREATE PROCEDURE sp_populate_etl_crossborder_screening()
BEGIN
    DECLARE etl_schema VARCHAR(200);
CALL get_etl_schema(etl_schema);

SELECT CONCAT("Processing crossborder screening report for schema: ", etl_schema) AS message;

SET @insert_sql = CONCAT(
        'INSERT INTO ', etl_schema, '.etl_crossborder_screening (',
          'patient_id, visit_id, visit_date, location_id, encounter_id, creator, date_created, date_last_modified, ',
          'place_of_residence_country, nationality, target_population, traveled_last_3_months, traveled_last_6_months, ',
          'traveled_last_12_months, duration_of_stay, frequency_of_travel, type_of_service',
        ') ',
        'SELECT ',
          'e.patient_id, e.visit_id, e.encounter_datetime AS visit_date, e.location_id, e.encounter_id, e.creator, e.date_created, ',
          'IF(MAX(o.date_created) > MIN(e.date_created), MAX(o.date_created), NULL) AS date_last_modified, ',
          'MAX(IF(o.concept_id=165915, o.value_coded, NULL)) AS place_of_residence_country, ',
          'MAX(IF(o.concept_id=168129, o.value_coded, NULL)) AS nationality, ',
          'MAX(IF(o.concept_id=166433, o.value_coded, NULL)) AS target_population, ',
          'MAX(IF(o.concept_id=162619, o.value_coded, NULL)) AS traveled_last_3_months, ',
          'MAX(IF(o.concept_id=165656, o.value_coded, NULL)) AS traveled_last_6_months, ',
          'MAX(IF(o.concept_id=162619, o.value_coded, NULL)) AS traveled_last_12_months, ',
          'MAX(IF(o.concept_id=162603, o.value_numeric, NULL)) AS duration_of_stay, ',
          'MAX(IF(o.concept_id=1732, o.value_coded, NULL)) AS frequency_of_travel, ',
          'MAX(IF(o.concept_id=168146, o.value_coded, NULL)) AS type_of_service ',
        'FROM encounter e ',
        'INNER JOIN person p ON p.person_id = e.patient_id AND p.voided = 0 ',
        'LEFT OUTER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 ',
        'AND o.concept_id IN (165915,168129,166433,162619,165656,162619,162603,1732,168146) ',
        'INNER JOIN (SELECT encounter_type_id, uuid, name FROM encounter_type WHERE uuid = ''6536A8A3-7B77-414D-A0F0-E08A7178FF0F'') et ON et.encounter_type_id = e.encounter_type ',
        'WHERE e.voided = 0 ',
        'GROUP BY e.patient_id, e.encounter_id;'
    );

PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT CONCAT("Completed processing crossborder screening report for schema: ", etl_schema) AS message;
END $$

DROP PROCEDURE IF EXISTS sp_populate_etl_crossborder_referral $$
CREATE PROCEDURE sp_populate_etl_crossborder_referral()
BEGIN
    DECLARE etl_schema VARCHAR(200);
CALL get_etl_schema(etl_schema);

SELECT CONCAT("Processing crossborder referral report for schema: ", etl_schema) AS message;

SET @insert_sql = CONCAT(
        'INSERT INTO ', etl_schema, '.etl_crossborder_referral (',
          'patient_id, encounter_id, visit_id, location_id, visit_date, nationality, ',
          'referring_facility_name, referred_facility_name, type_of_care, date_of_referral, ',
          'reason_for_referral, target_population, general_comments_if_reffered, referral_recommendation_continue_art, ',
          'referring_hc_provider, referring_hc_provider_email, referring_hc_provider_telephone, referring_hc_provider_cadre, ',
          'date_last_modified, creator, date_created, voided',
        ') ',
        'SELECT ',
          'e.patient_id, e.encounter_id, e.visit_id, e.location_id, e.encounter_datetime AS visit_date, ',
          'MAX(IF(o.concept_id=168129, o.value_coded, NULL)) AS nationality, ',
          'MAX(IF(o.concept_id=161550, o.value_text, NULL)) AS referring_facility_name, ',
          'MAX(IF(o.concept_id=162724, o.value_text, NULL)) AS referred_facility_name, ',
          'MAX(IF(o.concept_id=168146, o.value_coded, NULL)) AS type_of_care, ',
          'MAX(IF(o.concept_id=163181, o.value_datetime, NULL)) AS date_of_referral, ',
          'MAX(IF(o.concept_id=1887, o.value_coded, NULL)) AS reason_for_referral, ',
          'MAX(IF(o.concept_id=166433, o.value_coded, NULL)) AS target_population, ',
          'MAX(IF(o.concept_id=161011, o.value_text, NULL)) AS general_comments_if_reffered, ',
          'MAX(IF(o.concept_id=160632, o.value_text, NULL)) AS referral_recommendation_continue_art, ',
          'MAX(IF(o.concept_id=161103, o.value_text, NULL)) AS referring_hc_provider, ',
          'MAX(IF(o.concept_id=168130, o.value_text, NULL)) AS referring_hc_provider_email, ',
          'MAX(IF(o.concept_id=163152, o.value_text, NULL)) AS referring_hc_provider_telephone, ',
          'MAX(IF(o.concept_id=163556, o.value_coded, NULL)) AS referring_hc_provider_cadre, ',
          'IF(MAX(o.date_created) > MIN(e.date_created), MAX(o.date_created), NULL) AS date_last_modified, ',
          'e.creator, e.date_created, e.voided ',
        'FROM encounter e ',
        'INNER JOIN person p ON p.person_id = e.patient_id AND p.voided = 0 ',
        'LEFT OUTER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 ',
        'AND o.concept_id IN (161550,162724,168146,163181,1887,161011,160632,161103,168130,163152,163556,168129,166433) ',
        'INNER JOIN (SELECT encounter_type_id, uuid, name FROM encounter_type WHERE uuid = ''5C6DA02B-51E8-4B3D-BB67-BE8F75C4CCE1'') et ON et.encounter_type_id = e.encounter_type ',
        'WHERE e.voided = 0 ',
        'GROUP BY e.patient_id, e.encounter_id;'
    );

PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT CONCAT("Completed processing crossborder referral report for schema: ", etl_schema) AS message;
END $$

-- ------------------------------------------- running all procedures -----------------------------

DROP PROCEDURE IF EXISTS sp_first_time_crossborder_setup $$
CREATE PROCEDURE sp_first_time_crossborder_setup()
BEGIN
    DECLARE etl_schema VARCHAR(200);

    -- Get the ETL schema from helper (for logging)
CALL get_etl_schema(etl_schema);

SELECT CONCAT("Starting first-time crossborder setup for schema: ", etl_schema) AS message;

CALL sp_populate_etl_crossborder_screening();
CALL sp_populate_etl_crossborder_referral();

SELECT CONCAT("Completed first-time crossborder setup for schema: ", etl_schema) AS message;
END $$