-- Queries for the CronJob

CREATE FUNCTION view_count( INTEGER) RETURNS BIGINT AS '
    SELECT count(password_id)
    FROM views
    WHERE password_id = $1
    GROUP BY password_id;
    ' LANGUAGE SQL;

UPDATE passwords
    SET payload = NULL, expired = True
    WHERE expired = false 
        and (expire_after_views <= view_count(id) or (created_at + (expire_after_time *  interval '1 hour')) <= now()) ;