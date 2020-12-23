begin;
  update as_queue
  inner join
  (select task_id
   from as_queue
   where target in (%s)
     and status = 'QUEUED'
   order by last_change asc
   limit %s) as q using (task_id)
  set status = %s,
      last_change = now();
end;
