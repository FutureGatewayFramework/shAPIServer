#!/bin/bash
#
# FutureGateway db functions for shAPIServer.sh 
#

#
# Functions
#

# Execute an SQL query on FutureGateway DB
#
# exec_sql <query>
#
# Executes a given SQL query specified in <query> parameter wich can be a
# string or a filename. The function return 0 and provides query output
# or return 1 in case of failure and provides query error string
#
exec_sql() {
  [ $# -eq 0 ] &&\
    log ERROR No SQL query passed to exec_sql &&\
    return 1
  # Create RES and ERR query output files
  get_temp SQL_RES SQL_ERR
  [ -f "$1" ] &&\
    $MYSQL_CMD_ < $1 2>$SQL_ERR >$SQL_RES||\
    eval "$MYSQL_CMD_ \"-e ${@}\" 2>$SQL_ERR >$SQL_RES"
  SQL_XCD=$?
  [ $SQL_XCD -eq 0 ] &&\
    cat $SQL_RES ||\
    cat $SQL_ERR
  rm_temp SQL_ERR SQL_RES
  return $SQL_XCD
}

# Prepare a specified SQL query
#
#  prepare_sql <query_output> <query_file> [<qarg_1>, ... <qarg_2>]
#
# This function sustitute (%s)es specified in <query_file> with specified
# <qarg_i> parameters, placing the output into <query_output>
# Arguments are automatically converted in string or integers, however to
# force an integer value to be interpeted as a string use the syntax:
# \"<arg_i>\"
# The <query_output> can be a variable name or a file name
#
prepare_sql() {
  QUERY_VAR=$1
  [ $QUERY_VAR = "" ] &&\
    log ERROR Missing variable name in query preparation &&\
    exit 1
  shift 1
  QUERY_FILE=$1
  [ $QUERY_FILE = "" ] &&\
    log ERROR Missing query file name in query preparation &&\
    exit 1
  shift 1
  get_temp PREPARE_QUERY
  [ ! -f $QUERY_FILE ] &&\
    log "ERROR Unable to find specified query file: '"$QUERY_FILE"'" &&\
    exit 1
  cat $QUERY_FILE  > $PREPARE_QUERY
  # Loop over remaining arguments for query parameters
  for var in "$@"; do
    var=$(echo $var | sed s/\\//\\\\\\\\\\//g)
    is_number $var &&\
      sed -i'' "0,/%s/s//$var/" $PREPARE_QUERY ||\
      eval "sed -i'' \"0,/%s/s//\'$var\'/\" $PREPARE_QUERY"
  done
  [ -f $QUERY_VAR ] &&\
    eval "cp $PREPARE_QUERY $QUERY_VAR" ||\
    eval "${QUERY_VAR}=\"$(cat $PREPARE_QUERY)\""
  rm_temp PREPARE_QUERY
} 

#
# Initializations
#

# FutureGateway DB conneciton variables
FGDB_HOST=fgdb
FGDB_PORT=3306
FGDB_USER=fgapiserver
FGDB_PASS=fgapiserver_password
FGDB_NAME=fgapiserver

# MySQL variables
MYSQL_CFG=mysql.cfg
MYSQL_OPTS="--defaults-extra-file=$MYSQL_CFG -B -N -s"
MYSQL_CMD_="mysql $MYSQL_OPTS "

# Create mysql configuration
[ -f $MYSQL_CFG ] &&\
  rm -f $MYSQL_CFG 
cat >$MYSQL_CFG <<EOF
[client]
user = ${FGDB_USER}
port = ${FGDB_PORT}
password = ${FGDB_PASS}
host = ${FGDB_HOST}
database = ${FGDB_NAME}
EOF
