#! /bin/sh

##
## This script collects server usage data and then inserts the data into the psql
#  database. The script will be executed every minute using Linux’s crontab program.
##
## Usage: bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password
## Example: bash scripts/host_usage.sh localhost 5432 host_agent postgres password
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

#  Get server info
hostname=$(hostname -f)
memory_free=$(vmstat --unit M | tail -1 | awk -v col="4" '{print $col}')
cpu_idle=$(vmstat --unit M | tail -1 | awk -v col="15" '{print $col}')
cpu_kernel=$(vmstat --unit M | tail -1 | awk -v col="14" '{print $col}')
disk_io=$(vmstat --unit M -d | tail -1 | awk -v col="10" '{print $col}')
disk_available=$(df -BM / | tail -1 | awk '{print $4}' | sed 's/[^0-9]*//g')
timestamp=$(date "+%F %T")

# Construct INSERT statement
host_id_subquery="(SELECT id FROM host_info WHERE hostname='$hostname')";
host_usage_insert_statement="
INSERT INTO host_usage (
  host_id, memory_free, cpu_idle, cpu_kernel,
  disk_io, disk_available, timestamp
)
VALUES
  (
    $host_id_subquery, $memory_free,
    $cpu_idle, $cpu_kernel, $disk_io,
    $disk_available, '$timestamp'
  );"

# Execute INSERT statement
export PGPASSWORD=$psql_password
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$host_usage_insert_statement"

exit $?