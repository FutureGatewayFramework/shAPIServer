select
  task_id,
  target 
from as_queue
where status = %s 
order by last_change asc
limit %s;


