-- SAK-43881 START
alter table MFR_TOPIC_T add SEND_TO_CALENDAR NUMBER(1,0) null;
alter table MFR_TOPIC_T add CALENDAR_BEGIN_ID VARCHAR2(255) null;
alter table MFR_TOPIC_T add CALENDAR_END_ID VARCHAR2(255) null;
alter table MFR_OPEN_FORUM_T add SEND_TO_CALENDAR NUMBER(1,0) null;
alter table MFR_OPEN_FORUM_T add CALENDAR_BEGIN_ID VARCHAR2(255) null;
alter table MFR_OPEN_FORUM_T add CALENDAR_END_ID VARCHAR2(255) null;
-- SAK-43881 END

# #############################################################################################
# THIS NEEDS TO BE VERIFIED ON AN ORACLE DB - copied from the mysql script
# #############################################################################################

-- SAK-48423 START
-- Please read this and check your database
-- if you already have the column order_index column in table rbc_rating then you can skip this
ALTER TABLE rbc_rating ADD order_index INT DEFAULT null NULL;
UPDATE rbc_rating SET order_index = 0 WHERE order_index is NULL;

-- populate existing records with a default order
DROP TEMPORARY TABLE IF EXISTS temp_rbc_criterion;
DROP TEMPORARY TABLE IF EXISTS temp_rbc_rating;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_rbc_criterion AS ( SELECT criterion_id FROM rbc_rating GROUP BY criterion_id, order_index HAVING COUNT(order_index) > 1 );
CREATE TEMPORARY TABLE IF NOT EXISTS temp_rbc_rating ( id BIGINT, order_index INT );

DELIMITER //
DROP PROCEDURE IF EXISTS ORDERINDEX;
CREATE PROCEDURE ORDERINDEX() MODIFIES SQL DATA
BEGIN
   DECLARE cid BIGINT;
   DECLARE done INT DEFAULT FALSE;
   DECLARE n INT UNSIGNED DEFAULT 0;
   DECLARE c1 CURSOR FOR SELECT criterion_id FROM temp_rbc_criterion;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   SET n = ( SELECT COUNT(criterion_id) FROM temp_rbc_criterion WHERE criterion_id IS NOT NULL );
   IF n > 0 THEN
       OPEN c1;
       read_loop: LOOP
           FETCH c1 INTO cid;
           IF done THEN
               LEAVE read_loop;
           END IF;
           SET @rn = -1;
           INSERT INTO temp_rbc_rating ( select id, ( @rn:=@rn + 1 ) AS order_index FROM rbc_rating WHERE criterion_id = cid );
       end LOOP;
       CLOSE c1;
       UPDATE rbc_rating rr JOIN temp_rbc_rating trr on trr.id = rr.id SET rr.order_index = trr.order_index;
   END IF;
END;
//
DELIMITER ;

-- execute procdure
CALL ORDERINDEX();

-- cleanup
DROP PROCEDURE IF EXISTS ORDERINDEX;
DROP TEMPORARY TABLE IF EXISTS temp_rbc_criterion;
DROP TEMPORARY TABLE IF EXISTS temp_rbc_rating;
-- SAK-48423 END
