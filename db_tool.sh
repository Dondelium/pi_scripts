#!/bin/bash

USAGE="Usage: $0 {start|stop|restart|status}"
SUDO_FAIL="Non-sudo execution detected.\nThis script requires root level access as it controls services, and drive mounts.\nExiting:"
APP_NAME="PGSQL database"
SYS_NAME="postgresql"
DRIVE_NAME="/dev/sda1"
DRIVE_LOC="/home/pi/store"

start_app() {
    echo "Starting $APP_NAME..."
    systemctl start "$SYS_NAME"
    retval=$?
    if [ $retval -eq 0 ]; then
        echo "$APP_NAME started."
        return 0
    else
        echo "$APP_NAME failed to start!"
        return $retval
    fi
}

stop_app() {
    echo "Stopping $APP_NAME..."
    systemctl stop "$SYS_NAME"
    retval=$?
    if [ $retval -eq 0 ]; then
        echo "$APP_NAME stopped."
        return 0
    else
        echo "$APP_NAME failed to stop!"
        return $retval
    fi
}

status_app() {
    echo "Current status of $APP_NAME:"
    systemctl status "$SYS_NAME"
}

check_disk_is_mounted() {
    echo "Checking if $DRIVE_NAME is mounted..."
    val=$(sudo df -h | grep $DRIVE_LOC)
    if [ -z "$val" ] ; then
        return 0 # 0 is False: Disk is NOT mounted
    else
        return 1 # 1 is True: Disk IS mounted
    fi
} # I know, this is very counter bash, but just makes more sense: null for null, 1 for true...

mount_disk() {
    check_disk_mounted
    if [ $? -eq 0 ] ; then
        echo "Mounting drive $DRIVE_NAME..."
        mount "$DRIVE_NAME" "$DRIVE_LOC/"
        retval=$?
        if [ $retval -eq 0 ]; then
            echo "$DRIVE_NAME mounted."
            return 0
        else
            echo "$DRIVE_NAME failed to mount!"
            return $retval
        fi
    else
        echo "$DRIVE_NAME already mounted."
        return 0
    fi
}

umount_disk() {
    check_disk_mounted
    if [ $? -eq 1 ] ; then
        echo "Unmounting drive $DRIVE_NAME..."
        umount "$DRIVE_NAME"
        retval=$?
        if [ $retval -eq 0 ]; then
            echo "$DRIVE_NAME unmounted. Now safe to shut down / backup / reboot."
            return 0
        else
            echo "$DRIVE_NAME failed to unmounted!"
            return $retval
        fi
    else
        echo "$DRIVE_NAME already unmounted."
        return 0
    fi
}

if [ "$EUID" -ne 0 ] ; then
  echo -e "$SUDO_FAIL"
  exit 1
fi

case "$1" in
    start)
        mount_disk
        if [ $? -eq 0 ] ; then
            start_app
        fi
    ;;
    
    stop)
        stop_app
        umount_disk
    ;;
    
    restart)
        stop_app
        mount_disk
        start_app
    ;;
    
    status)
        status_app
    ;;
    
    *)
        echo $USAGE
        exit 1
    ;;
esac