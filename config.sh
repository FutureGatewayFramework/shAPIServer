#!/bin/bash
#
# Configuration file for bash implementation of the API server
#

# load configuration settings
. shAPIServer.conf

# List of used configuration variables
SHASD_CONFIG=(
  LOCK_FILE
  MAX_ACTIVE_TASKS
  POLLING_TIMEOUT
  INSTANCE_UUID_FILE
)

# Instance UUID is calculated using uuid() mysql function, it is generated 
# only once and stored into file specified by config value INSTANCE_UUID_FILE
# The UUID will remain the same untile the INSTANCE_UUID_FILE will be kept
instance_uuid() {
  UUID_VAR=$1
  [ "$UUID_VAR" = "" ] &&\
    log ERROR No uuid variable passed in instance uuid &&\
    exit 1
  if [ ! -f $INSTANCE_UUID_FILE ]; then
    prepare_sql QUERY\
                queries/get_uuid.sql
    QRES=$(exec_sql "$QUERY")
    [ $? -ne 0 ] &&\
      log ERROR "Unable to get service' instance ID: "$QRES &&\
      exit 1
    INSTANCE_UUID=$QRES
    echo "$INSTANCE_UUID" > $INSTANCE_UUID_FILE
  else
    INSTANCE_UUID=$(cat $INSTANCE_UUID_FILE)
  fi
  eval $UUID_VAR=$INSTANCE_UUID
  unset UUID_VAR
}

# Calculate the hash of service' configuration settings of file
# Configuration values stored in this file will be used to 
# calculate the configuration hash value using md5sum of a file
# made of <CONF_NAME>=<CONF_VALUE>
sh_config_hash() {
  HASH_VAR=$1
  [ "$HASH_VAR" = "" ] &&\
    log ERROR No hash variable passed in config hash &&\
    exit 1
  get_temp HASH_FILE
  for CONF_NAME in ${SHASD_CONFIG[@]}; do
    CONF_VALUE=${!CONF_NAME}
    echo "${CONF_NAME}=${CONF_VALUE}" >> $HASH_FILE
  done
  CONF_HASH=$(cat $HASH_FILE | md5sum | awk '{ print $1 }')
  rm_temp HASH_FILE
  eval $HASH_VAR"="$CONF_HASH
  unset HASH_VAR
}

# Register the service into the database (1st time)
register_service() {
  log DEBUG Config hash: $CONFIG_HASH
  prepare_sql QUERY\
              queries/add_service_to_registry.sql\
              $INSTANCE_UUID\
              $CONFIG_HASH
  get_temp QRES_REGISTER
  exec_sql $QUERY > $QRES_REGISTER
  [ $? -ne 0 ] &&\
    log ERROR "Unable to register service' configuration: "$(cat $QRES_REGISTER) &&\
    rm_temp QRES_REGISTER &&\
    exit 1
  rm_temp QRES_REGISTER
}

# Clean configuration values
clean_configuration_values() {
  prepare_sql QUERY\
              queries/delete_service_config_values.sql\
              $INSTANCE_UUID
  get_temp QRES_CLEAN
  exec_sql $QUERY > $QRES_CLEAN
  [ $? -ne 0 ] &&\
    log ERROR "Unable to register service' configuration: "$(cat $QRES_CLEAN) &&\
    rm_temp QRES_CLEAN &&\
    exit 1
  rm_temp QRES_CLEAN
}

# Store configuration values
store_configuration_values() {
  for CONF_NAME in ${SHASD_CONFIG[@]}; do
    CONF_VALUE=${!CONF_NAME}
    prepare_sql QUERY\
                queries/add_service_value_to_registry.sql\
                $INSTANCE_UUID\
                $CONF_NAME\
                $CONF_VALUE
    get_temp QRES_STORE_VALS
    exec_sql $QUERY > $QRES_STORE_VALS
    [ $? -ne 0 ] &&\
      log ERROR "Unable to register service' configuration '"${CONF_NAME}"="${CONF_VALUE}"': '"$(cat $QRES_STORE_VALS)"'" &&\
      rm_temp QRES_STORE_VALS &&\
      exit 1
    rm_temp QRES_STORE_VALS
  done
}

# Store configuration settings into the database
register_service_and_store_config() {
  sh_config_hash CONFIG_HASH
  register_service
  store_configuration_values
}

# Load service configuration from DB
load_db_configurations() {
  log DEBUG Loading configuration variables from DB
  for CONF_NAME in ${SHASD_CONFIG[@]}; do
    prepare_sql QUERY\
                queries/get_configuration_value.sql\
                $INSTANCE_UUID\
                $CONF_NAME
    get_temp QRES_CONFVAL
    exec_sql $QUERY > $QRES_CONFVAL
    [ $? -ne 0 ] &&\
      log ERROR "Unable to get service' configuration value for '"${CONF_NAME}"': '"$(cat $QRES_CONFVAL)"'" &&\
      rm_temp QRES_CONFVAL &&\
      exit 1
    CONF_VALUE=$(cat $QRES_CONFVAL | awk -F '\t' '{ print $1 }')
    eval $CONF_NAME"="$CONF_VALUE
    log DEBUG "  "$CONF_NAME"="$CONF_VALUE
    rm_temp QRES_CONFVAL
  done
}

# Calculate database configurations hash
db_config_hash() {
  HASH_VAR=$1
  [ "$HASH_VAR" = "" ] &&\
    log ERROR No hash variable passed in config hash &&\
    exit 1
  get_temp HASH_FILE
  for CONF_NAME in ${SHASD_CONFIG[@]}; do
    prepare_sql QUERY\
                queries/get_configuration_value.sql\
                $INSTANCE_UUID\
                $CONF_NAME
    get_temp QRES_CONFHASH
    exec_sql $QUERY > $QRES_CONFHASH
    [ $? -ne 0 ] &&\
      log ERROR "Unable to get service' configuration value for '"${CONF_NAME}"': '"$(cat $QRES_CONFHASH)"'" &&\
      rm_temp QRES_CONFHASH &&\
      exit 1
    CONF_VALUE=$(cat $QRES_CONFHASH | awk -F'\t' '{ print $1 }')
    echo "${CONF_NAME}=${CONF_VALUE}" >> $HASH_FILE
    rm_temp QRES_CONFHASH
  done  
  CONF_HASH=$(cat $HASH_FILE | md5sum | awk '{ print $1 }')
  rm_temp HASH_FILE
  eval $HASH_VAR"="$CONF_HASH
  unset HASH_VAR
}

update_sh_configurations() {
  log DEBUG Updating configuration file ...
  for CONF_NAME in ${SHASD_CONFIG[@]}; do
    eval CONF_VALUE"=$"$CONF_NAME
    sed -i'' s/^$CONF_NAME.*/$CONF_NAME=$CONF_VALUE/ shAPIServer.conf
    log DEBUG "  $CONF_NAME=$CONF_VALUE"
  done 
}

# Update service' hash value
update_service_hash() {
  prepare_sql QUERY\
              queries/update_service_hash.sql\
              $CONFIG_HASH\
              $INSTANCE_UUID
  get_temp QRES_SRVHASH
  exec_sql $QUERY > $QRES_SRVHASH
  [ $? -ne 0 ] &&\
    log ERROR "Unable to update service' hash '"${CONFIG_HASH}"': '"$(cat $QRES_SRVHASH)"'" &&\
    rm_temp QRES_SRVHASH &&\
    exit 1
  rm_temp QRES_SRVHASH
}

# Register and check service' configurations
register_and_check_config() {
  prepare_sql QUERY\
              queries/get_service_by_uuid.sql\
              $INSTANCE_UUID
  get_temp QRES_SRVBYUUID
  exec_sql $QUERY > $QRES_SRVBYUUID
  [ $? -ne 0 ] &&\
    log ERROR "Unable to load service' configuration: "$(cat $QRES_SRVBYUUID) &&\
    log ERROR "Query: "$QUERY &&\
      rm_temp QRES_SRVBYUUID &&\
      exit 1
  # Empty set or service details
  if [ -s $QRES_SRVBYUUID ]; then
    # Three hash values will be extracted: conf, registry, and db
    # conf !=  registry -> update registry and set db accordingly
    # db != registry -> update registry and set script values
    # else, no changes detected
    sh_config_hash SH_CONFIG_HASH
    db_config_hash DB_CONFIG_HASH
    DB_REGISTRY_HASH=$(cat $QRES_SRVBYUUID | awk -F'\t' '{ print $4 }')
    log DEBUG "Config Hashes: "
    log DEBUG "  SH - $SH_CONFIG_HASH"
    log DEBUG "  DB - $DB_CONFIG_HASH" 
    log DEBUG "  RG - $DB_REGISTRY_HASH"
    # conf != registry, db != registry, else
    if [ "$SH_CONFIG_HASH" != "$DB_REGISTRY_HASH" ]; then
      log INFO "Config variables are different from service registration, updating values"
      CONFIG_HASH=$SH_CONFIG_HASH
      update_service_hash
      clean_configuration_values
      store_configuration_values
    elif [ "$DB_REGISTRY_HASH" != "$DB_CONFIG_HASH" ]; then
      log INFO "Database configuration setting change detected, updating values"
      CONFIG_HASH=$DB_CONFIG_HASH
      update_service_hash
      load_db_configurations
      update_sh_configurations
    else
      log INFO "No service' configuration changes detected"
    fi
  else
    # Store configuration settings 
    log DEBUG "Registering service and storing service' configurations"$(cat $QRES_SRVBYUUID)
    register_service_and_store_config
  fi
  rm_temp QRES_SRVBYUUID
}
