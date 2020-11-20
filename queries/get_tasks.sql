begin;
  update as_queue
inner join
  (select task_id
  from as_queue
  where target in ('bare_executor')
    and status = 'QUEUED'
  order by last_change asc
      limit %s
  ) as q using
  (task_id)
  set status
  = 'SHASD_TAKEN',
    last_change = now
  ();
end;
select task_id,
  target_id,
  target,
  action,
  status,
  target_status,
  retry,
  creation,
  last_change
      check_ts,
  action_info
from as_queue
where status = 'SHASD_TAKEN';
end;


