#!/bin/bash
#
# FutureGateway tasks functions for shAPIServer.sh 
#

# Retrieve maxumum 'n' tasks from the queue
#
# $1 - Maximum number of tasks
# $@ - List of compatible executors
get_tasks() {
  prepare_sql QUERY\
              queries/get_tasks\
              10
  get_temp QRES_QTASKS
  exec_sql $QUERY > $QRES_QTASKS
  [ $? -ne 0 ] &&\
    log ERROR "Unable to load service' configuration: "$(cat $QRES_QTASKS) &&\
    log ERROR "Query: "$QUERY &&\
      rm_temp QRES_QTASKS &&\
      exit 1
  cat $QRES_QTASKS
}