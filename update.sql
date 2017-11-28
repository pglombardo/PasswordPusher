-- Update query for cronjob
UPDATE passwords
    SET payload = NULL, expired = True
    WHERE expired = false 
        and (expire_after_views <= view_count(id) or (created_at + (expire_after_time *  interval '1 hour')) <= now()) ;