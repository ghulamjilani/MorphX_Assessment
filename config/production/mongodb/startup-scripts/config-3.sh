#!/bin/sh

CONF=/opt/bitnami/mongodb/prod_conf/config-3.conf
DAEMON=/opt/bitnami/mongodb/bin/mongod
PIDFILE=/opt/bitnami/mongodb/tmp/mongodb-config-3.pid
PORT=27020 # This must be the same port as specified in the $CONF file

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
  EXEC="$(which numactl) -- $NUMACTL_ARGS $DAEMON --config $CONF"
else
  EXEC="$DAEMON -- --config $CONF"
fi

# Disable transparent hugepages
if test -f /sys/kernel/mm/transparent_hugepage/enabled
then
  echo "never" | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
fi

if test -f /sys/kernel/mm/transparent_hugepage/defrag
then
  echo "never" | sudo tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null
fi

echo "Going to start $DAEMON (conf: $CONF) on port $PORT"
echo "Command: $EXEC"
start-stop-daemon --background --start --chuid mongodb:mongodb --pidfile $PIDFILE --make-pidfile --exec $EXEC
