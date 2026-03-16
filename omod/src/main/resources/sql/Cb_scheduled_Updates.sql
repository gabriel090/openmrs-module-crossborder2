DROP PROCEDURE IF EXISTS sp_update_etl_crossborder_screening $$
CREATE PROCEDURE sp_update_etl_crossborder_screening(IN last_update_time DATETIME)
BEGIN
    DECLARE etl_schema VARCHAR(200);
CALL get_etl_schema(etl_schema);

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
        'WHERE e.voided = 0 AND (e.date_created >= last_update_time ',
          'OR e.date_changed >= last_update_time ',
          'OR e.date_voided >= last_update_time ',
          'OR o.date_created >= last_update_time ',
          'OR o.date_voided >= last_update_time) ',
        'GROUP BY e.patient_id, e.encounter_id ',
        'ON DUPLICATE KEY UPDATE ',
          'visit_date = VALUES(visit_date), ',
          'date_created = VALUES(date_created), ',
          'date_last_modified = VALUES(date_last_modified), ',
          'place_of_residence_country = VALUES(place_of_residence_country), ',
          'nationality = VALUES(nationality), ',
          'target_population = VALUES(target_population), ',
          'traveled_last_3_months = VALUES(traveled_last_3_months), ',
          'traveled_last_6_months = VALUES(traveled_last_6_months), ',
          'traveled_last_12_months = VALUES(traveled_last_12_months), ',
          'duration_of_stay = VALUES(duration_of_stay), ',
          'frequency_of_travel = VALUES(frequency_of_travel), ',
          'type_of_service = VALUES(type_of_service), ',
          'creator = VALUES(creator);'
    );

PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END $$

DROP PROCEDURE IF EXISTS sp_update_etl_crossborder_referral $$
CREATE PROCEDURE sp_update_etl_crossborder_referral(IN last_update_time DATETIME)
BEGIN
    DECLARE etl_schema VARCHAR(200);
CALL get_etl_schema(etl_schema);

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
          'MAX(IF(o.concept_id=163556, o.value_text, NULL)) AS referring_hc_provider_cadre, ',
          'IF(MAX(o.date_created) > MIN(e.date_created), MAX(o.date_created), NULL) AS date_last_modified, ',
          'e.creator, e.date_created, e.voided ',
        'FROM encounter e ',
        'INNER JOIN person p ON p.person_id = e.patient_id AND p.voided = 0 ',
        'LEFT OUTER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 ',
        'AND o.concept_id IN (161550,162724,168146,163181,1887,161011,160632,161103,168130,163152,163556,168129,166433) ',
        'INNER JOIN (SELECT encounter_type_id, uuid, name FROM encounter_type WHERE uuid = ''5C6DA02B-51E8-4B3D-BB67-BE8F75C4CCE1'') et ON et.encounter_type_id = e.encounter_type ',
        'WHERE e.voided = 0 AND (e.date_created >= last_update_time ',
          'OR e.date_changed >= last_update_time ',
          'OR e.date_voided >= last_update_time ',
          'OR o.date_created >= last_update_time ',
          'OR o.date_voided >= last_update_time) ',
        'GROUP BY e.patient_id, e.encounter_id ',
        'ON DUPLICATE KEY UPDATE ',
          'visit_date = VALUES(visit_date), ',
          'nationality = VALUES(nationality), ',
          'referring_facility_name = VALUES(referring_facility_name), ',
          'referred_facility_name = VALUES(referred_facility_name), ',
          'type_of_care = VALUES(type_of_care), ',
          'date_of_referral = VALUES(date_of_referral), ',
          'reason_for_referral = VALUES(reason_for_referral), ',
          'target_population = VALUES(target_population), ',
          'general_comments_if_reffered = VALUES(general_comments_if_reffered), ',
          'referral_recommendation_continue_art = VALUES(referral_recommendation_continue_art), ',
          'referring_hc_provider = VALUES(referring_hc_provider), ',
          'referring_hc_provider_email = VALUES(referring_hc_provider_email), ',
          'referring_hc_provider_telephone = VALUES(referring_hc_provider_telephone), ',
          'referring_hc_provider_cadre = VALUES(referring_hc_provider_cadre), ',
          'date_last_modified = VALUES(date_last_modified), ',
          'creator = VALUES(creator), ',
          'voided = VALUES(voided);'
    );

PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END $$

-- ----------------------------  scheduled updates ---------------------

DROP PROCEDURE IF EXISTS cb_sp_scheduled_updates $$
CREATE PROCEDURE cb_sp_scheduled_updates()
BEGIN
    DECLARE etl_schema VARCHAR(200);
    DECLARE update_script_id INT(11);
    DECLARE last_update_time DATETIME;

CALL get_etl_schema(etl_schema);

SET @get_last_update = CONCAT(
        'SELECT max(start_time) into last_update_time from ',
        etl_schema, '.etl_script_status where stop_time is not null'
    );
PREPARE stmt FROM @get_last_update;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @log_start = CONCAT(
        'INSERT INTO ', etl_schema, '.etl_script_status(script_name, start_time) ',
        'VALUES(''scheduled_updates'', NOW())'
    );
PREPARE stmt FROM @log_start;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET update_script_id = LAST_INSERT_ID();

    -- Call the update procedures (they already have their own schema logic)
CALL sp_update_etl_crossborder_referral(last_update_time);
CALL sp_update_etl_crossborder_screening(last_update_time);

-- Update stop time
SET @log_stop = CONCAT(
        'UPDATE ', etl_schema, '.etl_script_status SET stop_time=NOW() where id = ', update_script_id
    );
PREPARE stmt FROM @log_stop;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Clean up old logs
SET @cleanup = CONCAT(
        'DELETE FROM ', etl_schema, '.etl_script_status ',
        'where script_name in ("KenyaEMR_Data_Tool", "scheduled_updates") ',
        'and start_time < DATE_SUB(NOW(), INTERVAL 12 HOUR)'
    );
PREPARE stmt FROM @cleanup;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT update_script_id;
END $$