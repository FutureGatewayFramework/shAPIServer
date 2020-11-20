insert into srv_registry (
  uuid,
  creation,
  last_access,
  enabled,
  cfg_hash)
values (
  %s,
  now(),
  now(),
  true,
   %s);
