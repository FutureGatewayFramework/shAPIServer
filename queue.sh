#!/bin/bash
#
# Queue functions
#

#
# Functions
#

# Get queue record fields of task specified in task_id variable
get_queue_record() {
  get_temp QUERY QRES_SETSTATUS
  prepare_sql $QUERY\
              queries/get_queue_record.sql\
              $task_id
  exec_sql $QUERY > $QRES_SETSTATUS
  [ $? -ne 0 ] &&\
    log ERROR "Unable to get queue record for task_id: '"${task_id}"': '"$(cat $QRES_SETSTATUS)"'" &&\
    rm_temp QUERY QRES_SETSTATUS &&\
    return 1
  # Retrieve queue record values
  target_id=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $2 }')
  target=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $3 }')
  action=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $4 }')
  status=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $5 }')
  target_status=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $6 }')
  retry=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $7 }')
  creation=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $8 }')
  last_change=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $9 }')
  check_ts=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $10 }')
  action_info=$(cat $QRES_SETSTATUS | awk -F'\t' '{ print $11 }')
  rm_temp QUERY QRES_SETSTATUS
  log DEBUG Queue record:
  QFIELDS=(
    "task_id"\
    "target_id"\
    "target"\
    "action"\
    "status"\
    "target_status"\
    "retry"\
    "creation"\
    "last_change"\
    "check_ts"\
    "action_info"\
  )
  for qf in ${QFIELDS[@]}; do
    eval "QVALUE=\$$qf"
    log DEBUG "\t${qf}=$(echo $QVALUE)"
  done
  QRECSUM=$(checksum_queue_record)
  PREV_QRECSUM=$QRECSUM
  log DEBUG  "Queue record checksum: $QRECSUM"
  return 0
}

# Calculate queue record value checksum
checksum_queue_record() {
  get_temp CHKQREC
  for qf in ${QFIELDS[@]}; do
    eval "QVALUE=\$$qf"
    echo "${qf}=$(echo $QVALUE)" >>$CHKQREC
  done
  QRECSUM=$(cat $CHKQREC | md5sum | awk '{ print $1 }' | xargs echo)
  echo $QRECSUM
  return 0
}

# Determine if queue record has changed
check_queue_record() {
  QRECSUM=$(checksum_queue_record)
  [ "$QRECSUM" = "$PREV_QRECSUM" ] &&\
    return 0
  PREV_QRECSUM=$QRECSUM
  return 1
}

# Update queue record fields
update_queue_record() {
  CHKQREC=$()
  [ $check_queue_record ] &&\
    log DEBUG "No queue record changes detected" &&\
    return
  log DEBUG "Queue record changes detected, updating db" &&\
  get_temp QUERY QRES_UPDATEQREC
  prepare_sql $QUERY\
              queries/update_queue_record.sql\
              $target_id\
              $target\
              $action\
              $status\
              $target_status\
              $retry\
              $creation\
              $check_ts\
              $action_info\
              $task_id 
  exec_sql $QUERY > $QRES_UPDATEQREC
  [ $? -ne 0 ] &&\
    log ERROR "Unable to update queue record for task_id: '"${task_id}"': '"$(cat $QRES_UPDATEQREC)"'" &&\
    rm_temp QUERY QRES_UPDATEQREC &&\
    return 1
  rm_temp QUERY QRES_UPDATEQREC
  return 0
}

# Inesert a file entry for the given task
insert_task_file() {
  TASK_FILE_ARG=$1
  TASK_FILE_TASKID=$2
  TASK_FILE_PATH=$3
  get_temp INSQUERY INSTASKRES
  prepare_sql $INSQUERY\
              queries/insert_task_file.sql\
              $TASK_FILE_TASKID\
              $TASK_FILE_TASKID\
              $TASK_FILE_ARG\
              $TASK_FILE_PATH
  exec_sql $INSQUERY > $INSTASKRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable to insert task file: '"$TASK_FILE_ARG"' for task_id: '"${task_id}"': '"$(cat $INSTASKRES)"'" &&\
    rm_temp INSQUERY INSTASKRES &&\
    return 1
  rm_temp INSQUERY INSTASKRES
  return 0
}

# Update file entry for the given task
update_task_file() {
  TASK_FILE_ARG=$1
  TASK_FILE_TASKID=$2
  TASK_FILE_PATH=$3
  get_temp UPDQUERY UPDTASKRES
  prepare_sql $UPDQUERY\
              queries/update_task_file.sql\
              $TASK_FILE_PATH\
              $TASK_FILE_TASKID\
              $TASK_FILE_ARG
  exec_sql $UPDQUERY > $UPDTASKRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable to update task file: '"$TASK_FILE_ARG"' for task_id: '"${task_id}"': '"$(cat $UPDTASKRES)"'" &&\
    rm_temp UPDQUERY UPDTASKRES &&\
    return 1
  rm_temp UPDQUERY UPDTASKRES
  return 0
}

# Insert or update a task file entry
insert_or_update_task_file() {
  TASK_FILE=$1
  TASK_FILE_PATH=${action_info}/$TASK_FILE
  [ ! -f "${action_info_path}/${TASK_FILE}" ] &&\
    log ERROR "Unable to update file '"${TASK_FILE_PATH}", the file is missing" &&\
    return 1
  log DEBUG "Inserting or updating task file: '"$TASK_FILE_PATH"'"
  get_temp QUERY TASKFILECOUNTRES
  prepare_sql QUERY\
              queries/task_file_count.sql\
              $task_id\
              $TASK_FILE
  exec_sql $QUERY > $TASKFILECOUNTRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable to get info for task file: '"$TASK_FILE"' for task_id: '"${task_id}"': '"$(cat $TASKFILECOUNTRES)"'" &&\
    rm_temp QUERY TASKFILECOUNTRES &&\
    return 1
  # Get file count value
  FILECOUNT=$(cat $TASKFILECOUNTRES)
  rm_temp QUERY TASKFILECOUNTRES
  if [ $FILECOUNT -eq 0 ]; then
    # Insert task record
    log DEBUG "Inserting file: '"$TASK_FILE"' for task_id: '"$task_id"'"
    insert_task_file "$TASK_FILE" "$task_id" "$action_info"
  else 
    log DEBUG "Updating file: '"$TASK_FILE"' for task_id: '"$task_id"'"
    update_task_file "$TASK_FILE" "$task_id" "$action_info"
  fi
  return 0
}

# Retrieve a list of registered task files
process_task_files() {
  log DEBUG Retrieving task files
  get_temp TFILESQ TASKFILESRES
  prepare_sql TFILESQ\
              queries/get_task_files.sql\
              $task_id
  exec_sql $TFILESQ > $TASKFILESRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable to get info for task file: '"$TASK_FILE"' for task_id: '"${task_id}"': '"$(cat $TASKFILESRES)"'" &&\
    rm_temp TFILESQUERY TASKFILESRES &&\
    return 1
  if [ -s $TASKFILESRES ]; then
    log DEBUG Updating output files for task: $task_id
    while read task_file; do
      task_file_id=$(echo $task_file | awk '{ print $1 }')
      task_file_name=$(echo $task_file | awk '{ print $2 }')
      task_file_path=$(echo $task_file | awk '{ print $3 }')
      [ "$task_file_name" = "$SHBE_STDOUT" -o\
        "$task_file_name" = "$SHBE_STDERR" ] &&\
        continue 
      log DEBUG "\toutput file id: "$task_file_id" name: '"$task_file_name"' path: '"$task_file_path"'"
      insert_or_update_task_file $task_file_name 
    done < $TASKFILESRES
  else
    log DEBUG No files to update for task: $task_id
  fi  
  rm_temp TFILESQ TASKFILESRES
  return 0
}

# Update task status in task table
update_task_status() {
  log DEBUG Updating task status
  get_temp UPDATETASKQUERY UPDATETASKRES
  prepare_sql UPDATETASKQUERY\
              queries/update_task.sql\
              $status\
              $task_id
  exec_sql $UPDATETASKQUERY > $UPDATETASKRES
  [ $? -ne 0 ] &&\
    log ERROR "Unable update task having id: '"${task_id}"': "$(cat $UPDATETASKRES)"'" &&\
    rm_temp UPDATETASKQUERY UPDATETASKRES &&\
    return 1
  rm_temp UPDATETASKQUERY UPDATETASKRES
  return 0
}

# Finalize task information after its execution
finalize_task() {
  # Insert/Update error/output files if necessary
  HAS_OUT=$(echo $SHBE_STDOUT | grep "^\." | wc -l)
  [ $HAS_OUT -eq 0 ] &&\
    insert_or_update_task_file $SHBE_STDOUT ||\
    log DEBUG No output file specified
  HAS_ERR=$(echo $SHBE_STDOUT | grep "^\." | wc -l)
  [ $HAS_ERR -eq 0 ] &&\
    insert_or_update_task_file $SHBE_STDERR ||\
    log DEBUG No error file specified 
  # Update paths in task_output_file table if necessary
  # Set task status
  process_task_files &&\
  update_task_status &&\
  return 0
  return 1
}

# Verifies consistency of the queued task specified in $task_id variable
verify_queued_task() {
  # Task id
  [ "${task_id}" = "" ] &&\
    log ERROR "Received empty task_id" &&\
    return 1

  # Retrieve queue record elements
  get_queue_record $task_id

  # Action
  [ "${action}" = "" ] &&\
    status="ABORTED" &&\
    log ERROR "No action specified for task id: '"$task_id"'" &&\
    return 1

  # Target info
  [ "${action_info}" = "" ] &&\
    task_id="ABORTED" &&\
    log ERROR "No target info specified for task id: '"$task_id"' with action: '"$action"'" &&\
    return 1

  # EI' path for action_info (it may be different from API Server path)
  action_info_path=${IOSANDBOX_DIR}/$(basename ${action_info})
  log debug "Action info: $action_info_path"
  [ ! -d $action_info_path ] &&\
    status="ABORTED" &&\
    log ERROR "No target info directory: '"$action_info_path"' available for task id: '"$task_id"' with action: '"$action"'" &&\
    return 1

  # Submit json file
  submit_json=${action_info_path}/${task_id}.json
  log debug "submit_json: "$submit_json
  [ ! -f $submit_json ] &&\
    status="ABORTED" &&\
    log ERROR "No task description file: '"$submit_json"', found" &&\
    return 1

  return 0
}

# Retrieve task' executor interface at infrastructure level
infra_executor_interface() {
  NUM_APP_INFRAS=$(cat $submit_json | jq .application.infrastructures | jq length)
  RND_APP_INFRA=$((RANDOM%NUM_APP_INFRAS))
  get_temp SEL_INFRA
  cat $submit_json  | jq .application.infrastructures[$RND_APP_INFRA] > $SEL_INFRA
  [ -s $SEL_INFRA ] &&\
    cat $SEL_INFRA |\
        jq .parameters |\
        jq -r '.[] | select(.name=="executor_interface").value' ||\
    (status="ABORTED" &&\
     log ERROR "Unable to get executor_interface for task '"$task_id"'" &&\
     rm_temp SEL_INFRA &&\
     return 1;)
  rm_temp SEL_INFRA
}

# Task infrastructure parameters (with same EI)
infra_parameters() {
  NUM_APP_INFRAS=$(cat $submit_json | jq .application.infrastructures | jq length)
  RND_APP_INFRA=$((RANDOM%NUM_APP_INFRAS))
  get_temp SEL_INFRA
  cat $submit_json  | jq .application.infrastructures[$RND_APP_INFRA] > $SEL_INFRA
  [ -s $SEL_INFRA ] &&\
    cat $SEL_INFRA |\
        jq -r '.parameters[] | [.name,.value]|@tsv' ||\
    (status="ABORTED" &&\
     log ERROR "Unable to get infrastructure for task '"$task_id"'" &&\
     rm_temp SEL_INFRA &&\
     return 1;)
  rm_temp SEL_INFRA
}
