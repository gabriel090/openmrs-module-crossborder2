DELIMITER $$
DROP PROCEDURE IF EXISTS create_crossborder_etl_tables $$
CREATE PROCEDURE create_crossborder_etl_tables()
BEGIN
    DECLARE etl_schema VARCHAR(200);
    DECLARE current_schema VARCHAR(200);
    DECLARE tenant_suffix VARCHAR(100);

    -- Get current schema and determine ETL schema
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

    -- Drop tables from main OpenMRS schema if they exist (wrong location)
    SET @drop_from_main_referral = CONCAT('DROP TABLE IF EXISTS ', current_schema, '.etl_crossborder_referral;');
PREPARE stmt FROM @drop_from_main_referral;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @drop_from_main_screening = CONCAT('DROP TABLE IF EXISTS ', current_schema, '.etl_crossborder_screening;');
PREPARE stmt FROM @drop_from_main_screening;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @drop_etl_referral = CONCAT('DROP TABLE IF EXISTS ', etl_schema, '.etl_crossborder_referral;');
PREPARE stmt FROM @drop_etl_referral;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @drop_etl_screening = CONCAT('DROP TABLE IF EXISTS ', etl_schema, '.etl_crossborder_screening;');
PREPARE stmt FROM @drop_etl_screening;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @create_referral = CONCAT('
        CREATE TABLE ', etl_schema, '.etl_crossborder_referral
        (
            patient_id                               INT,
            encounter_id                             INT,
            visit_id                                 INT,
            location_id                              INT,
            visit_date                               DATE,
            nationality                              INT(15),
            referring_facility_name                  VARCHAR(255),
            referred_facility_name                   VARCHAR(255),
            type_of_care                             INT(15),
            date_of_referral                         DATETIME,
            target_population                        INT(15),
            reason_for_referral                      VARCHAR(255),
            general_comments_if_reffered             VARCHAR(255),
            referral_recommendation_continue_art     VARCHAR(255),
            referring_hc_provider                    VARCHAR(255),
            referring_hc_provider_email              VARCHAR(255),
            referring_hc_provider_telephone          VARCHAR(255),
            referring_hc_provider_cadre              VARCHAR(255),
            creator                                  INT,
            date_created                             DATETIME,
            date_last_modified                       DATETIME,
            voided                                   INT,
            INDEX (patient_id),
            INDEX (visit_id),
            INDEX (visit_date),
            INDEX (encounter_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ');

PREPARE stmt FROM @create_referral;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT CONCAT("Successfully created ", etl_schema, ".etl_crossborder_referral table") AS message;

-- Create table etl_crossborder_screening in the correct ETL schema
SET @create_screening = CONCAT('
        CREATE TABLE ', etl_schema, '.etl_crossborder_screening
        (
            patient_id                         INT(11),
            encounter_id                       INT(11) NOT NULL primary key,
            visit_id                           INT(11),
            location_id                        INT(11),
            visit_date                         DATE,
            country                            VARCHAR(255),
            lhss_site                          VARCHAR(255),
            place_of_residence_country         VARCHAR(255),
            place_of_residence_county_district VARCHAR(255),
            place_of_residence_village         VARCHAR(255),
            place_of_residence_landmark        VARCHAR(255),
            nationality                        INT(11),
            nationality_other                  VARCHAR(255),
            target_population                  INT(11),
            target_population_other            VARCHAR(255),
            traveled_last_3_months             INT(11),
            traveled_last_6_months             INT(11),
            traveled_last_12_months            INT(11),
            duration_of_stay                   INT(15),
            frequency_of_travel                INT(11),
            frequency_of_travel_other          VARCHAR(255),
            type_of_service                    INT(11),
            service_other                      VARCHAR(255),
            creator                            INT(11),
            date_created                       DATETIME,
            date_last_modified                 DATETIME,
            INDEX (patient_id),
            INDEX (visit_id),
            INDEX (visit_date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ');

PREPARE stmt FROM @create_screening;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT CONCAT("Successfully created ", etl_schema, ".etl_crossborder_screening table") AS message;

END $$
DELIMITER ;
