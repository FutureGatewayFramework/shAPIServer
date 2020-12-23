#!/bin/bash
#
# logging functions for Bash scripts
#

#
# Functions
#

# logging conifiguration
LOG_FORMAT=(
  "date +%Y%m%d%H%M%S.%4N"
  "printf \" \""
  "line_num"
  "printf \": \""
  "printf \"\$LEVEL \""
)

LOG_LEVELS=(
  "INFO"
  "WARN"
  "ERROR"
  "DEBUG"
)

LOG_LEVEL=INFO
LOG_FILE=logging.log
LOG_ROTATE=1
LOG_ROTATE_SIZE=$((512*1024*1204))
LOG_OUTPUT=(
    "${LOG_FILE}"
    ""
)

# Get bash script line numbers
line_num(){
  [ "$1" = "" ] &&\
    LNNUM_MAXJ=${#BASH_LINENO[@]} &&\
    LNNUM_MAXJ=$((LNNUM_MAXJ-1)) ||\
    LNNUM_MAXJ=$1
  j=0
  for ((i=${#BASH_LINENO[@]}-1;i>=0;i--)); do
    [ $j -lt $LNNUM_MAXJ ] &&\
      printf '[%s:%s]' "${FUNCNAME[i]}" "${BASH_LINENO[i]}" &&\
      j=$((j+1)) ||\
      break
  done
  #printf "($LINENO)"
 }

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
  MESSAGE=$(echo -e "$@")
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
      LOG_SIZE=$(stat --format="%s" $LOG_FILE)
      [ $LOG_SIZE -gt $LOG_ROTATE_SIZE ] &&\
        cp $LOG_FILE $(date +%Y%m%d%H%M%S)_${LOG_FILE} &&\
        echo "" > $LOG_FILE
    fi
  done
  return 0
}

# Initialization, uses script argument to overload log file name
[ "$1" != "" ] &&\
  LOG_OUTPUT[0]=$1
[ "$2" != "" ] &&\
  LOG_LEVEL=$2

