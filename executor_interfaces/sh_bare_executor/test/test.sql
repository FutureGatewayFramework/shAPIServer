-- Insert dummy test application using bare executor
insert into task values (1, now(), now(), 1, 'sh bare executor test', 'QUEUED', '/Users/riccardobruno/Downloads/src/shAPIServer/executor_interfaces/sh_bare_executor/test', 'brunor');
insert into as_queue values (1, NULL, "sh_bare_executor", "SUBMIT", "SUBMIT", NULL, 0, now(), now(), now(), '/Users/riccardobruno/Downloads/src/shAPIServer/executor_interfaces/sh_bare_executor/test');
