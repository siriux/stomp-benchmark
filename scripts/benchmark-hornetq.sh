#!/bin/bash
#
# This shell script automates running the stomp-benchmark [1] against the
# HornetQ project [2].
#
# [1]: http://github.com/chirino/stomp-benchmark
# [2]: http://www.jboss.org/hornetq
#

HORNETQ_VERSION=2.2.5.Final
HORNETQ_DOWNLOAD="http://downloads.jboss.org/hornetq/hornetq-${HORNETQ_VERSION}.tar.gz"
BENCHMARK_HOME=~/benchmark
. `dirname "$0"`/benchmark-setup.sh

#
# Install the distro
#
HORNETQ_HOME="${BENCHMARK_HOME}/hornetq-${HORNETQ_VERSION}"
if [ ! -d "${HORNETQ_HOME}" ]; then
  cd ${BENCHMARK_HOME}
  wget "$HORNETQ_DOWNLOAD"
  tar -zxvf hornetq-${HORNETQ_VERSION}.tar.gz
  rm -rf hornetq-${HORNETQ_VERSION}.tar.gz
  
  # Adjust the start script so that it execs java.
  perl -pi -e 's|^java|exec java|' "${HORNETQ_HOME}/bin/run.sh"
  
  #
  # Add the stomp connector to the configuration.
  perl -pi -e 's| <\/acceptors>|<acceptor name="stomp-acceptor">
      <factory-class>org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory</factory-class>
      <param key="protocol"  value="stomp"/>
      <param key="host"  value="0.0.0.0"/>
      <param key="port"  value="61613"/>
    </acceptor>
<\/acceptors>|' "${HORNETQ_HOME}/config/stand-alone/non-clustered/hornetq-configuration.xml"

  #
  # Add the destinations that the benchmark will be using.
 perl -pi -e 's|^</configuration>|<queue name="loadq-0"><entry name="/queue/loadq-0"/></queue>
    <queue name="loadq-1"><entry name="/queue/loadq-1"/></queue>
    <queue name="loadq-2"><entry name="/queue/loadq-2"/></queue>
    <queue name="loadq-3"><entry name="/queue/loadq-3"/></queue>
    <queue name="loadq-4"><entry name="/queue/loadq-4"/></queue>
    <queue name="loadq-5"><entry name="/queue/loadq-5"/></queue>
    <queue name="loadq-6"><entry name="/queue/loadq-6"/></queue>
    <queue name="loadq-7"><entry name="/queue/loadq-7"/></queue>
    <queue name="loadq-8"><entry name="/queue/loadq-8"/></queue>
    <queue name="loadq-9"><entry name="/queue/loadq-9"/></queue>
    <queue name="load_me_up-0"><entry name="/queue/load_me_up-0"/></queue>

    <topic name="loadt-0"><entry name="/topic/loadt-0"/></topic>
    <topic name="loadt-1"><entry name="/topic/loadt-1"/></topic>
    <topic name="loadt-2"><entry name="/topic/loadt-2"/></topic>
    <topic name="loadt-3"><entry name="/topic/loadt-3"/></topic>
    <topic name="loadt-4"><entry name="/topic/loadt-4"/></topic>
    <topic name="loadt-5"><entry name="/topic/loadt-5"/></topic>
    <topic name="loadt-6"><entry name="/topic/loadt-6"/></topic>
    <topic name="loadt-7"><entry name="/topic/loadt-7"/></topic>
    <topic name="loadt-8"><entry name="/topic/loadt-8"/></topic>
    <topic name="loadt-9"><entry name="/topic/loadt-9"/>
    </topic></configuration>|' "${HORNETQ_HOME}/config/stand-alone/non-clustered/hornetq-jms.xml"
 
fi

#
# Sanity Cleanup
rm -rf "${HORNETQ_HOME}/data/*"
rm -rf "${HORNETQ_HOME}/logs/*"

#
# Start the server
#
CONSOLE_LOG="${HORNETQ_HOME}/console.log"
rm "${CONSOLE_LOG}" 2> /dev/null
cd "${HORNETQ_HOME}/bin"
./run.sh 2>&1 > "${CONSOLE_LOG}" &
HORNETQ_PID=$!
echo "Started HornetQ with PID: ${HORNETQ_PID}"
sleep 5
cat "${CONSOLE_LOG}"

#
# Run the benchmark
#
cd ${BENCHMARK_HOME}/stomp-benchmark
"${BENCHMARK_HOME}/bin/sbt" run --topic-prefix=jms.topic. --queue-prefix=jms.queue. reports/hornetq-${HORNETQ_VERSION}.json

# Kill the server
kill -9 ${HORNETQ_PID}
