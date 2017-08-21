#!/bin/sh
#
# Starts HMServer.
#

LOGLEVEL_HMServer=5
CFG_TEMPLATE_DIR=/etc/config_templates
STARTWAITFILE=/var/status/HMServerStarted

source /var/hm_mode 2>/dev/null

# skip this startup in LAN Gateway mode
[[ ${HM_MODE} == "HMLGW" ]] && exit 0

if [[ ${HM_MODE} == "HmIP" ]]; then
  HM_SERVER_TYPE="HMIPServer"
  HM_SERVER=/opt/HMServer/HMIPServer.jar
  HM_SERVER_ARGS="/etc/crRFD.conf"
  PIDFILE=/var/run/HMIPServer.pid
else
  HM_SERVER_TYPE="HMServer"
  HM_SERVER=/opt/HMServer/HMServer.jar
  HM_SERVER_ARGS=""
  PIDFILE=/var/run/HMServer.pid
fi

init() {
	export JAVA_HOME=/opt/java/
	export PATH=$PATH:$JAVA_HOME/bin
	if [ ! -e /etc/config/log4j.xml ] ; then
		cp $CFG_TEMPLATE_DIR/log4j.xml /etc/config
	fi
}

waitStartupComplete() {
	STEPS=150
	for i in $(seq 1 $STEPS); do
		sleep 2
		echo -n "."
		if [[ -e ${STARTWAITFILE} ]]; then
			echo "OK"
			break
		fi
		if [[ ${i} -eq ${STEPS} ]]; then
			echo "ERROR"
		fi
	done
}

start() {
	echo -n "Starting ${HM_SERVER_TYPE}: "
	init
	start-stop-daemon -b -S -q -m -p $PIDFILE --exec java -- -Xmx128m -Dos.arch=arm -Dlog4j.configuration=file:///etc/config/log4j.xml -Dfile.encoding=ISO-8859-1 -jar ${HM_SERVER} ${HM_SERVER_ARGS}
	echo -n "."
	waitStartupComplete
}
stop() {
	echo -n "Stopping ${HM_SERVER_TYPE}: "
	rm -f $STARTWAITFILE
	start-stop-daemon -K -q -p $PIDFILE
	rm -f $PIDFILE
	echo "OK"
}
restart() {
	stop
	start
}

case "$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  restart|reload)
	restart
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

