#!/bin/bash
#
# Bash implementation of the API server
#

# tools functions
. tools.sh

# logging import and customisation
LOG_FILE=shAPIServer.log
LOG_LEVEL=DEBUG
. logging.sh $LOG_FILE $LOG_LEVEL

# Check for compatibility issues before start the server is also may produce
# several aliases used by next includes (do not move this line)
check_compatibility

# database functions
. fgdb.sh

# tasks functions
. tasks.sh

# APIServer configurations, see shAPIerver.conf
. config.sh

# queue functions
. queue.sh

# Interruption  handlers
int_handler() {
  log INFO "User interruption detected"
  [ -f $LOCK_FILE ] &&\
    log DEBUG "Removing lock file: '"$LOCK_FILE"'" &&\
    rm -f $LOCK_FILE
  exit 0
}
exit_handler() {
  log INFO "API Server daemon terminated"
  cleanup_temp
}
error_handler() {
  log ERROR "Script error occurred"
  exit 1
}
trap int_handler INT
trap exit_handler EXIT
trap error_handler ERR

# Retrieve the number of actie tasks of this APIServer instance
get_active_tasks() {
  INSTANCE_ID=$1
  get_temp QUERY QRES
  prepare_sql $QUERY\
              queries/get_active_tasks.sql\
              SHAS_${INSTANCE_ID}
  exec_sql $QUERY > $QRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable to get the number of ative queue elements: '"$(cat $QRES_BOOK)"'" &&\
    rm_temp QUERY QRES &&\
    exit 1
  cat $QRES
  rm_temp QUERY QRES
}

# Book a given set of queue records
book_tasks() {
  BOOK_ID=$1
  shift 1
  EIS=$@ 
  get_temp QBOOK QRES_BOOK
  prepare_sql $QBOOK\
              queries/book_tasks.sql\
              "${EIS:1:${#EIS}-2}"\
              $(min $TASKS_PER_LOOP\
                    $((MAX_ACTIVE_TASKS-NUM_ACTIVE_TASKS)))\
              SHAS_${BOOK_ID}
  exec_sql $QBOOK > $QRES_BOOK
  [ $? -ne 0 ] &&\
    log ERROR "Unable to book queue records: '"$(cat $QRES_BOOK)"'" &&\
    rm_temp QBOOK QRES_BOOK &&\
    exit 1
  rm_temp QBOOK QRES_BOOK
}

# Get booked tasks
get_tasks() {
  QUEUE_TASKS=()
  get_temp QUERY QRES_GET
  prepare_sql $QUERY\
              queries/get_tasks.sql\
              SHAS_${BOOK_ID}\
              $(min $TASKS_PER_LOOP\
                    $((MAX_ACTIVE_TASKS-NUM_ACTIVE_TASKS)))\
  log debug "query: $QUERY"
  exec_sql $QUERY > $QRES_GET
  [ $? -ne 0 ] &&\
    log ERROR "Unable to get queue records: '"$(cat $QRES_GET)"'" &&\
    rm_temp QUERY QRES_GET &&\
    exit 1
  while read tr; do
    task_id=$(echo $tr | awk '{print $1}')
    target_executor=$(echo $tr | awk '{print $2}')
    QUEUE_TASKS+=("${task_id}|${target_executor}")
  done < $QRES_GET
  rm_temp QUERY QRES_GET  
}

# Starting-up
log INFO "Starting shAPIServer daemon, lock file in '"$LOCK_FILE"'"
log INFO "Log file in '"$LOG_FILE"'"

# Generate lock file
[ ! -f $LOCK_FILE ] &&\
  touch $LOCK_FILE ||
  log WARN "Lock file '"$LOCK_FILE"' already present"

# Generate/read instance UUID
instance_uuid INSTANCE_UUID
log INFO "Instance id: $INSTANCE_UUID"
# Short UUID is used to book queue records that will be owned by this instance
SH_UUID=${INSTANCE_UUID: -12}

# Register or check service configuration
register_and_check_config

# Get a comma separated string of supported executor interfaces
# The 'sh_executor' is the default executor interface name supported by this
# executor interface
SH_DIR_EXECUTOR_INTERFACES=$(/bin/ls -1 executor_interfaces | xargs printf '%s, ')
SH_EXECUTOR_INTERFACES=$(echo "sh_executor, $SH_DIR_EXECUTOR_INTERFACES" | sed s/,.$//)
log INFO "Supported executor interfaces: ("$SH_EXECUTOR_INTERFACES")"

#
# shAPIServer main loop
#
log INFO "Polling"
while [ -f $LOCK_FILE ]; do
  # Extract tasks from QUEUE
  NUM_ACTIVE_TASKS=$(get_active_tasks $SH_UUID)
  log DEBUG "Active tasks: $NUM_ACTIVE_TASKS having booking id: 'SHAS_"$SH_UUID"'"
  book_tasks $SH_UUID $SH_EXECUTOR_INTERFACES
  get_tasks $SH_UUID
  log DEBUG "Got ${#QUEUE_TASKS[@]} booked tasks: '"${QUEUE_TASKS[@]}"'"
  for tr in ${QUEUE_TASKS[@]}; do
    task_id=$(echo $tr | awk -F'|' '{print $1}')
    target_executor=$(echo $tr | awk -F'|' '{print $2}')
    if [ "$target_executor" = "sh_executor" ]; then
      # Infrastructure based executor interface
      NULL=$(verify_queued_task) &&\
        target_executor=$(infra_executor_interface) ||\
        log ERROR "Task validation error for task having id: '"$task_id"'"
      [ "$target_executor" = "" ] &&\
        log ERROR "No application level target executor for: '"$task_id"', skipping" &&\
        continue
    fi
    log DEBUG "Executing task_id: '"$task_id"' with executor: '"$target_executor"'"
    executor_interfaces/${target_executor}/${target_executor} $task_id &
  done
  # Process extracted tasks with corresponding EIs
  # ...
  # Wait before the next loop
  log INFO "Waiting"
  sleep $POLLING_TIMEOUT
done
log DEBUG "Removed lock file: '"$LOCK_FILE"'"
