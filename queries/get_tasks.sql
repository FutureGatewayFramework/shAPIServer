select
  task_id 
from as_queue
where status = %s 
  and target = %s
order by last_change asc
limit %s;


