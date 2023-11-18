#! /bin/sh

##
## This script collects hardware specification data and then inserts the data into
# the psql instance. You can assume that hardware specifications are static, so the script
# will be executed only once.
##
## Usage: ./scripts/host_info.sh psql_host psql_port db_name psql_user psql_password
## Example: ./scripts/host_info.sh "localhost" 5432 "host_agent" "postgres" "mypassword"
##

# Parsing CLI arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Gather host hardware specifications
lscpu_out=$(lscpu)
hostname=$(hostname -f)
cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | grep -E "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | grep -E "^Model name:" | awk '{$1=$2=""; print $0}' | xargs)
cpu_mhz=$(echo "$lscpu_out" | grep -E "^CPU MHz:" | awk '{print $3}' | xargs)
l2_cache=$(echo "$lscpu_out" | grep -E "^L2 cache:" | awk '{print $3}' | sed 's/[^0-9]*//g' | xargs)
timestamp=$(date "+%F %T")
total_mem=$(vmstat --unit M | tail -1 | awk '{print $4}' | xargs)

# Construct INSERT statement
host_info_insert_statement="INSERT INTO host_info
(
  hostname,
  cpu_number,
  cpu_architecture,
  cpu_model,
  cpu_mhz,
  l2_cache,
  \"timestamp\",
  total_mem
)
VALUES
(
  '$hostname',
  $cpu_number,
  '$cpu_architecture',
  '$cpu_model',
  $cpu_mhz,
  $l2_cache,
  '$timestamp',
  $total_mem
);"

# Execute INSERT statement
export PGPASSWORD=$psql_password
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$host_info_insert_statement"

exit $?