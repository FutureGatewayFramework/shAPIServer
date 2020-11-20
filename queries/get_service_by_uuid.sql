select creation,
       last_access,
       enabled,
       cfg_hash
from srv_registry
where uuid = %s;
