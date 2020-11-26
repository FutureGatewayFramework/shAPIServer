#!/bin/bash
#
# Tools for bash implementation of the API server
#

#
# Functions
#

# Create and register a new temporary file
get_temp() {
    VARS=($@)
    [ "$VARS" = "" ] &&\
      log ERROR Passed empty variable name for temp file &&\
      return 1
    for var in ${VARS[@]}; do
      TMP=$(mktemp)
      [ "$TMP" = "" ] &&\
        log ERROR Unable to create a temporary file &&\
        exit 1
      TMP_FILES+=($TMP)
      TMP_VARS+=($var)
      eval ${var}=${TMP}
    done
}

# Remove a registered temporary file
rm_temp() {
    VARS=($@)
    [ "$VARS" = "" ] &&\
      log ERROR Passed empty variable name for temp file &&\
      return 1
    for var in ${VARS[@]}; do
      ITH_VAR=""
      for ((i=0; i<${#TMP_VARS[@]}; i++)); do
        if [ "${TMP_VARS[i]}" = "$var" ]; then
          ITH_VAR=$i
          break
        fi
      done
      if [ "$ITH_VAR" != "" ]; then
        ITH_TMP_VAR=${TMP_VARS[$ITH_VAR]}
        ITH_TMP_FILE=${TMP_FILES[$ITH_VAR]}
        TMP_FILES=(${TMP_FILES[@]/"$ITH_TMP_FILE"})
        TMP_VARS=(${TMP_VARS[@]/"$ITH_TMP_VAR"})
        CMD="$ITH_TMP_VAR='' && unset $ITH_TMP_VAR"
        eval $CMD
      else
        log WARN Could not find variable: ${TMP_VARS[ITH_VAR]}
      fi
    done
}

# List temp files
list_temp() {
    for var in ${VARS[@]}; do
      ITH_VAR=""
      for ((i=0; i<${#TMP_VARS[@]}; i++)); do
        if [ "${TMP_VARS[i]}" = "$var" ]; then
          ITH_VAR=$i
          break
        fi
      done
      if [ "$ITH_VAR" != "" ]; then
        ITH_TMP_VAR=${TMP_VARS[$ITH_VAR]}
        ITH_TMP_FILE=${TMP_FILES[$ITH_VAR]}
        echo $ITH_TMP_VAR"="$ITH_TMP_FILE
      else
        log WARN Could not find variable: ${TMP_VARS[ITH_VAR]}
      fi
    done
}

# Remove all registered temporary files
cleanup_temp() {
  if [ ${#TMP_FILES[@]} -ne 0 ]; then
    log DEBUG Removing ${#TMP_FILES[@]} registered temporary files ...
    for tmp in  ${TMP_FILES[@]}; do
      if [ -f $tmp ]; then
        rm -f $tmp
        log DEBUG "  $tmp removed"
       else
        log DEBUG "  $tmp skipped"
       fi
    done
    log DEBUG done
  else
    log DEBUG No temporary files to clean
  fi
  TMP_FILES=()
  TMP_VARS=()
}

# Check for any compatibility issue inside hosting machine
check_compatibility() {
  LOG_HOSTOS=$(uname)
  if [ "$LOG_HOSTOS" = "Darwin" ]; then
    BREW_PKG=$(which brew)
    [ "$BREW_PKG" = "" ] &&\
      log ERROR mandatory 'brew' command not found &&\
      exit 1
    BREW_COREUTILS=$(brew list --formula | grep coreutils | wc -l | xargs echo)
    # Following commands and aliases are necessary to be compatible
    #  gstat (coreutils)
    #  gdate (coreutils)
    #  gsed (gnu-sed)
    [ $BREW_COREUTILS -eq 0 ] &&\
      log ERROR missing mandatory brew package: 'coreutils' &&\
      exit 1
    BREW_GNU_SED=$(brew list --formula | grep gnu-sed | wc -l | xargs echo)  
    [ $BREW_GNU_SED -eq 0 ] &&\
      log ERROR missing mandatory brew package: 'gnu-sed' &&\
      exit 1
    # Overload incompatible commands
    shopt -s expand_aliases
    alias stat=gstat
    alias date=gdate
    alias sed=gsed
  fi
  JQ=$(which jq)
  [ "$JQ" = "" ] &&\
    log ERROR mandatory 'jq' utility not found, please install it with brew &&\
    exit 1
  JQ=$(which md5sum)
  [ "$JQ" = "" ] &&\
    log ERROR mandatory 'md5sum' utility not found, please install it with brew &&\
    exit 1
  log DEBUG Compatibility check passed
}

# Check if a givent variable is a number and anreturn 0 in such a case 
is_number() {
  [ "$1" = "NULL" -o "$1" = "null" ] &&\
    return 0
  [ -n "$1" -a "$1" -eq "$1" ] 2>/dev/null &&\
    return 0
  return 1
}


#
# Initializations
#

# Temporary files
[ -z ${TMP_FILES+x} -a\
  -z ${TMP_VARS+x} ] &&\
  TMP_FILES=() &&\
  TMP_VARS=()
