update as_queue
  set target_id=%s,
      target=%s,
      action=%s,
      status=%s,
      target_status=%s,
      retry=%s,
      creation=str_to_date(%s, '%Y-%m-%dT%TZ'),
      last_change=now(),
      check_ts=str_to_date(%s, '%Y-%m-%dT%TZ'),
      action_info=%s
  where task_id=%s;
