#!/bin/bash
#
# Test script for sh_bare_executor executor interface
#
echo "Test start at: "$(date)
echo "Script arguments:"
echo "  ARG1: "$1
echo "  ARG2: "$2
echo "  ARG3: "$3
echo "Working directory: "$(pwd)
echo "Home directory: "$HOME
echo "Sleeping for a while (30 secs.) ..."
sleep 3
echo "Producing output file: test_output.txt"
base64 /dev/urandom | head -c 1024 >test_output.txt
echo "Output file md5: "$(md5sum test.jd | awk '{ print $1 }')
echo "Listing workind directory: "
ls -alrt .
echo "Test end at: "$(date)

