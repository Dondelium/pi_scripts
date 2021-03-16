#!/bin/bash

USER="pi"
APP_NAME="portal"
APP_DIR="/home/pi/internal_server"
APP_FILE="server.js"
KWARGS="--max-old-space-size=256"
LOG_DIR="/var/log/$APP_NAME"
LOG_FILE="$LOG_DIR/log.log"
NODE_EXEC="/usr/local/lib/nodejs/bin/node"

USAGE="Usage: $0 {start|stop|restart|status|cron}"

start_app() {
    mkdir -p "$LOG_DIR"
    chown $USER:$USER "$LOG_DIR"
    
    echo "Starting $APP_NAME..."
    echo "cd $APP_DIR && $NODE_EXEC $APP_DIR/$APP_FILE $KWARGS 1> $LOG_FILE 2>&1 &" | sudo -i -u root
    echo "$APP_NAME started."
    
    chmod a+r "$LOG_FILE"
}

stop_app() {
    echo "Stopping $APP_NAME..."
    ps aux | grep "[n]ode" | while read -r line
    do
        arr=($line)
        echo "Killing pid ${arr[1]}"
        kill ${arr[1]}
    done
    echo "$APP_NAME stopped."
}

status_app() {
    echo "Current list of running $APP_NAME instances:"
    ps aux | grep "[n]ode" | while read -r line
    do
        arr=($line)
        echo "pid: ${arr[1]} %CPU: ${arr[2]} %MEM: ${arr[3]}"
    done
}

reboot_check() {
    ps aux | grep "[n]ode" | while read -r line
    do
        echo "$(date) $APP_NAME detected. Exiting..."
        exit 1
    done
    if [[ $? -eq 1 ]]; then
        exit 0
    fi
    mv ${LOG_FILE} "${LOG_FILE}_$(date +"%Y-%m-%d_%T")"
    echo "$(date) $APP_NAME not running... attempting restart"
    start_app
}

case "$1" in
    start)
        start_app
    ;;
    
    stop)
        stop_app
    ;;
    
    restart)
        stop_app
        start_app
    ;;
    
    status)
        status_app
    ;;
    
    cron)
        reboot_check
    ;;
    
    *)
        echo $USAGE
        exit 1
    ;;
esac

# echo "cd /home/pi/internal_server && /usr/local/lib/nodejs/bin/node /home/pi/internal_server/server.js --max-old-space-size=256 1> /var/log/portal/log.log 2>&1 &" | sudo -i -u root
