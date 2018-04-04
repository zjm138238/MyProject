#!/bin/sh  
TO_EMAIL=15602207579@163.com
IP=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

notify_orientdb() {
    mailsubject="ip:$IP orientdb service is closed"
    mailbody="`date '+%F %H:%M:%S'`: ip:$IP orientdb service is closed, please check it"
    echo $mailbody | mail -s "$mailsubject" $TO_EMAIL
}

notify_keepalived() {
    mailsubject="ip:$IP keepalived service is closed"
    mailbody="`date '+%F %H:%M:%S'`: ip:$IP keepalived service is closed, please check it"
    echo $mailbody | mail -s "$mailsubject" $TO_EMAIL
}


PID=`ps auxw | grep 'orientdb.www.path' | grep java | grep -v grep | awk '{print $2}'`
if [ "x$PID" = "x" ]
then
    notify_orientdb
fi       

A=`ps -ef | grep "keepalived -D" | grep -v grep | wc -l`
if [ $A -eq 0 ];then                               
      notify_keepalived
fi