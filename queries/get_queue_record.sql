select task_id,
       target_id,
       target,
       action,
       status,
       target_status,
       retry,
       date_format(creation, '%Y-%m-%dT%TZ') creation,
       date_format(last_change, '%Y-%m-%dT%TZ') last_change,
       date_format(check_ts, '%Y-%m-%dT%TZ') check_ts,
       action_info
from as_queue
where task_id=%s;
