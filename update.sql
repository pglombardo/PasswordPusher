-- Update query for cronjob
UPDATE passwords
    SET payload = repeat(' ' , 64), expired = True
    WHERE ( expired = false 
        and (expire_after_views <= view_count(id) or (created_at + (expire_after_time *  interval '1 hour')) <= now()) )
        or payload = NULL ;