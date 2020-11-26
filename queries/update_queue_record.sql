update as_queue
  set target_id=%s,
      target=%s,
      action=%s,
      status=%s,
      target_status=%s,
      retry=%s,
      creation=%s,
      last_change=now(),
      check_ts=%s,
      action_info=%s,
  where task_id=%s;
