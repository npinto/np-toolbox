#!/bin/bash

set -e
set -x

trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo "exit $? due to $previous_command"' EXIT

# Update environment with prefix variables (EPREFIX, etc.)
source $(dirname $0)/update_env.sh
