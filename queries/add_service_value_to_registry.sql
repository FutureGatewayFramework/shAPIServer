insert into srv_config
set uuid=%s,
    name=%s,
    value=%s,
    enabled=TRUE,
    created=now(),
    modified=now();
