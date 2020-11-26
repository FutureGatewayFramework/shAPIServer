#!/bin/bash
#
# Bash implementation of the API server
#

LOG_FILE=shAPIServer.log

# logging import and customisation
. logging.sh $LOG_FILE

# tools functions
. tools.sh

# Check for compatibility issues before start the server is also may produce
# several aliases used by next includes (do not move this line)
check_compatibility

# database functions
. fgdb.sh

# tasks functions
. tasks.sh

# APIServer configurations, see shAPIerver.conf
. config.sh

# Interruption  handlers
int_handler() {
  log INFO "User interruption detected"
  [ -f $LOCK_FILE ] &&\
    log DEBUG "Removing lock file: '"$LOCK_FILE"'" &&\
    rm -f $LOCK_FILE
}
exit_handler() {
  log INFO "API Server daemon terminated"
  cleanup_temp
}
trap int_handler INT
trap exit_handler EXIT

# Starting-up
log INFO "Starting shAPIServer daemon, lock file in '"$LOCK_FILE"'"
log INFO "Log file in '"$LOG_FILE"'"


#
# shAPIServer main loop
#

# Generate lock file
[ ! -f $LOCK_FILE ] &&\
  touch $LOCK_FILE ||
  log WARN "Lock file '"$LOCK_FILE"' already present"

# Generate/read instance UUID
instance_uuid INSTANCE_UUID
log INFO "Instance id: $INSTANCE_UUID"

# Register or check service configuration
register_and_check_config
while [ -f $LOCK_FILE ]; do
  log INFO "Polling"
  # Extract tasks from QUEUE
  # ...
  # Process extracted tasks with corresponding EIs
  # ...
  # Wait before the next loop
  log INFO "Waiting"
  sleep $POLLING_TIMEOUT
done
log DEBUG "Removed lock file: '"$LOCK_FILE"'"
