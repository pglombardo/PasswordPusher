-- Function needed for CronJob
CREATE FUNCTION view_count( BIGINT) RETURNS BIGINT AS '
    SELECT count(password_id)
    FROM views
    WHERE password_id = $1
    GROUP BY password_id;
    ' LANGUAGE SQL;
