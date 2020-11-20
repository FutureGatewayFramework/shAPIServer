#!/bin/bash
#
# FutureGateway db functions for shAPIServer.sh 
#

# FutureGateway DB conneciton variables
FGDB_HOST=127.0.0.1
FGDB_PORT=3306
FGDB_USER=fgapiserver
FGDB_PASS=fgapiserver_password
FGDB_NAME=fgapiserver

# MySQL variables
MYSQL_CFG=mysql.cfg
MYSQL_OPTS="--defaults-extra-file=$MYSQL_CFG -B -N -s"
MYSQL_CMD_="mysql $MYSQL_OPTS -e "

# Execute an SQL query on FutureGateway DB
#
# $@ SQL query
#
exec_sql() {
  SQL_QRY=$@
  get_temp SQL_RES SQL_ERR
  $MYSQL_CMD_ "$SQL_QRY" 2>$SQL_ERR >$SQL_RES
  [ $? -eq 0 ] &&\
    cat $SQL_RES &&\
    rm_temp SQL_ERR SQL_RES &&\
    return 0
  cat $SQL_ERR
  rm_temp SQL_ERR SQL_RES
  return 1
}

# Prepare a specified SQL query
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
  cat $QUERY_FILE | tr '\n' ' ' > $PREPARE_QUERY
  # Loop over remaining arguments for query parameters
  for var in $@; do
    is_number $var &&\
      sed -i'' "s/%s/$var/" $PREPARE_QUERY ||\
      sed -i'' "s/%s/\'$var\'/" $PREPARE_QUERY
  done
  eval "${QUERY_VAR}=\"$(cat $PREPARE_QUERY)\""
  rm_temp PREPARE_QUERY
} 

#
# Init mysql
#
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


#SQL_CMD="select count(*) from as_queue;"
#exec_sql $SQL_CMD