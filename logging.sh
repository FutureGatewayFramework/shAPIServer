#!/bin/bash
#
# logging functions for Bash scripts
#

# Compatibility for date and stat commands in MacOS can be only ensured by
# homebrew package: 'coreutils'
LOG_HOSTOS=$(uname)
if [ "$LOG_HOSTOS" = "Darwin" ]; then
  LOG_STAT=gstat &&\
  LOG_DATE=gdate
else
  LOG_STAT="stat"
  LOG_DATE=date
fi

# logging conifiguration

LOG_FORMAT=(
  "$LOG_DATE +%Y%m%d%H%M%S.%4N"
  "printf \": \""
  "printf \"\$LEVEL \""
)

LOG_LEVELS=(
  "INFO"
  "WARN"
  "ERROR"
  "DEBUG"
)

LOG_LEVEL=DEBUG
LOG_FILE=logging.log
LOG_ROTATE=1
LOG_ROTATE_SIZE=$((512*1024*1204))
LOG_OUTPUT=(
    "${LOG_FILE}"
    ""
)

# log function
#
# $1 - Log level
# $@ - Log message
#
log() {
  LEVEL=$(echo $1 | awk '{print toupper($0)}')
  # take care of levels
  for ((i=0; i<${#LOG_LEVELS[@]}; i++)); do
    ITH_LEVEL=${LOG_LEVELS[$i]}
    [ "$ITH_LEVEL" = "$LEVEL" ] &&\
      REQ_LEVEL=$i &&\
      break
  done
  [ $i -gt ${#LOG_LEVELS[@]} ] &&\
    return
  for ((i=0; i< ${#LOG_LEVELS[@]}; i++)); do
    ITH_LEVEL=${LOG_LEVELS[$i]}
    [ "$ITH_LEVEL" = "$LOG_LEVEL" ] &&\
      CFG_LEVEL=$i &&\
      break
  done
  [ $i -gt ${#LOG_LEVELS[@]} ] &&\
    return
  # get message to log
  [ $REQ_LEVEL -gt $CFG_LEVEL ] && return
  shift 1
  MESSAGE=$@
  # take care of format
  FMT_MSG=""
  for ((i=0; i< ${#LOG_FORMAT[@]}; i++)); do
    FMT_COMMAND=${LOG_FORMAT[$i]}
    FMT_MSG_PART=$(eval $FMT_COMMAND)
    FMT_MSG=${FMT_MSG}$FMT_MSG_PART
  done
  # Log output
  LOG_ENTRY=${FMT_MSG}${MESSAGE}
  for ((i=0; i<${#LOG_OUTPUT[@]}; i++)); do
    [ "${LOG_OUTPUT[i]}" != "" ] &&\
      LOG_FILE=${LOG_OUTPUT[i]} &&\
      echo $LOG_ENTRY >> ${LOG_FILE} ||\
      echo "$LOG_ENTRY"
    if [ -f "$LOG_FILE" ]; then
      # Take care of rotating log file
      LOG_SIZE=$($LOG_STAT  --format="%s" $LOG_FILE)
      [ $LOG_SIZE -gt $LOG_ROTATE_SIZE ] &&\
        cp $LOG_FILE $($LOG_DATE +%Y%m%d%H%M%S)_${LOG_FILE} &&\
        echo "" > $LOG_FILE
    fi
  done
  return 0
}


