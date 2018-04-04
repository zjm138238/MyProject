#!/bin/sh

usage() {
        echo -e "Usage: bin/custom/orientdb_tools.sh COMMAND\n"
        echo "       -h|--help                            help to input"
        echo "       stop                                 stop orientdb server"
        echo "       status                               show orientdb status"
        echo "       logs                                 show orientdb log"
        echo "       start <database>(notclean|clean)     start orientdb server,and <database> refers to whether or not to clean the local databases,the value of <database> is 'notclean' or 'clean'"
        echo "       init <user_name> <password> <node_name> <master_ip_1> <master_ip_2> <master_ip_3>    init new orientdb Installation package,node_name is orientdb node name(not support '_'),master_ip is orientdb machine of master role"
}

if [ "$#" -eq "0" ]
then
        usage  
        exit 1
fi

USER_NAME=user_name
MASTER_IP=master_ip
REPLICA_IP_1=replica_ip_1
REPLICA_IP_2=replica_ip_2
PRG="$0"
PRGDIR=`dirname "$PRG"`
ORIENTDB_HOME=`cd "$PRGDIR/../.." ; pwd`


#设置orientdb.sh文件
setOrientdbScriptFile() {
    echo "setting to bin/orientdb.sh"
    cp $ORIENTDB_HOME/bin/custom/template_orientdb.sh $ORIENTDB_HOME/bin/custom/orientdb.sh
    #替换userName为$USER_NAME
    sed -i "s/userName/$USER_NAME/" $ORIENTDB_HOME/bin/custom/orientdb.sh
    mv -f $ORIENTDB_HOME/bin/custom/orientdb.sh $ORIENTDB_HOME/bin/
}

#设置orientdb_tools.sh文件
setOrientdbToolsScriptFile() {
    echo "setting to bin/custom/orientdb_tools.sh"
    #只匹配替换第一次出现的值
    sed -i "0,/USER_NAME/{s/USER_NAME=[^,]*/USER_NAME=$USER_NAME/};
    0,/MASTER_IP/{s/MASTER_IP=[^,]*/MASTER_IP=$MASTER_IP/};
    0,/REPLICA_IP_1/{s/REPLICA_IP_1=[^,]*/REPLICA_IP_1=$REPLICA_IP_1/};
    0,/REPLICA_IP_2/{s/REPLICA_IP_2=[^,]*/REPLICA_IP_2=$REPLICA_IP_2/}" $ORIENTDB_HOME/bin/custom/orientdb_tools.sh
}

#设置hazelcast.xml文件
setHazelcastXmlFile() {
    #删除hazelcast.xml文件中的<network></network>
    echo "setting to config/hazelcast.xml"
    sed -i "/<network>/,/<\/network>/d" $ORIENTDB_HOME/config/hazelcast.xml 
    sed "s/MASTER_IP/$MASTER_IP/;s/REPLICA_IP_1/$REPLICA_IP_1/;s/REPLICA_IP_2/$REPLICA_IP_2/" $ORIENTDB_HOME/bin/custom/insert_hazelcast_xml.txt > $ORIENTDB_HOME/bin/custom/temp_insert_hazelcast_xml.txt
    #重新插入hazelcast.xml文件中的<network></network>
    sed -i "/<\/properties>/ r $ORIENTDB_HOME/bin/custom/temp_insert_hazelcast_xml.txt" $ORIENTDB_HOME/config/hazelcast.xml 
    rm -f $ORIENTDB_HOME/bin/custom/temp_insert_hazelcast_xml.txt
}

#设置开启自动备份功能
setBackup() {
    echo "setting to config/automatic-backup.json"
    \cp $ORIENTDB_HOME/bin/custom/automatic-backup.json $ORIENTDB_HOME/config
    #删除一段匹配的内容
    sed -i "/OAutomaticBackup/,/<\/handler>/d" $ORIENTDB_HOME/config/orientdb-server-config.xml 
    #插入insert_config_backup.txt文件内容
    sed -i "/<handlers>/ r $ORIENTDB_HOME/bin/custom/insert_config_backup.txt" $ORIENTDB_HOME/config/orientdb-server-config.xml 
}

#设置orientdb用户名、密码、节点名
setOrientdbUserNameAndPasswordAndNodeName() {
    rm -rf $ORIENTDB_HOME/databases/*
/usr/bin/expect <<-EOF  
    set timeout 20                        
    spawn $ORIENTDB_HOME/bin/dserver.sh
    expect "password"  
    send "$PASSWORD\r"
    expect "confirm"  
    send "$PASSWORD\r"
    expect "Node name" 
    send "$NODE_NAME\r"
    expect "|ONLINE|"
    puts "wait for it......"     
    expect "OrientDB Server is active"
    puts "wait for it......"    
    expect eof
EOF
    #修改orientdb登录用户名
    echo "setting to config/orientdb-server-config.xml"
    old_user=`grep -w "resources=\"*\"" $ORIENTDB_HOME/config/orientdb-server-config.xml |awk -F\" '{print $6}'`        
    sed -i "s/name=\"$old_user\"/name=\"$USER_NAME\"/" $ORIENTDB_HOME/config/orientdb-server-config.xml
}

#设置orientdb-server-config.xml文件
setOrientdbServerConfigXmlFile() {
    echo "setting to config/orientdb-server-config.xml"
    #删除一段匹配的内容
    sed -i "/<properties>/,/<\/properties>/d" $ORIENTDB_HOME/config/orientdb-server-config.xml 
    #插入insert_config_properties.txt文件内容
    sed -i "/<\/users>/ r $ORIENTDB_HOME/bin/custom/insert_config_properties.txt" $ORIENTDB_HOME/config/orientdb-server-config.xml 
}


##############################################


case $1 in
    start) 
        if [ "$#" -eq "1" ]
        then
            echo "Error: Too few parameters"
            exit 1
        fi

        case $2 in
            notclean)
                #关闭本地机器
                $ORIENTDB_HOME/bin/shutdown.sh >/dev/null 2>&1
                #重启本地orientdb机器
                $ORIENTDB_HOME/bin/orientdb.sh start
                $ORIENTDB_HOME/bin/orientdb.sh logs
                ;;
            clean)
                #关闭本地机器
                $ORIENTDB_HOME/bin/shutdown.sh >/dev/null 2>&1
                #清空本地数据库
                rm -rf $ORIENTDB_HOME/databases/*
                #重启本地orientdb机器
                $ORIENTDB_HOME/bin/orientdb.sh start
                $ORIENTDB_HOME/bin/orientdb.sh logs
                ;;
            *) 
                echo "Error: Parameter error"
                exit 1
                ;;
        esac
        ;;
    init)
        if [ "$#" -ne "7" ]
        then
            echo "Error: Too few parameters"
            exit 1
        fi
        USER_NAME=$2
        PASSWORD=$3
        NODE_NAME=$4
        MASTER_IP=$5
        REPLICA_IP_1=$6
        REPLICA_IP_2=$7

        #确认输入信息
        echo "输入信息: user_name=$USER_NAME password=$PASSWORD node_name=$NODE_NAME 
        master_ip_1=$MASTER_IP master_ip_2=$REPLICA_IP_1 master_ip_3=$REPLICA_IP_2"
        read -p  "请确认您输入的信息（y|n）：" -t 60 status #等待60秒
        [[ -z $status ]] && exit 1
        [ "x$status" != "xy" ] && exit 1

        # init <user_name> <password> <node_name> <master_ip> <replica_ip_1> <replica_ip_2>
        #设置orientdb.sh文件
        setOrientdbScriptFile
        #设置orientdb_tools.sh文件
        setOrientdbToolsScriptFile
        #设置hazelcast.xml文件
        setHazelcastXmlFile
        #设置开启自动备份功能
        setBackup  
        #设置orientdb用户名、密码、节点名
        setOrientdbUserNameAndPasswordAndNodeName
        #设置orientdb-server-config.xml文件
        setOrientdbServerConfigXmlFile
        ;;
    stop)
        $ORIENTDB_HOME/bin/orientdb.sh stop    
        ;;
    logs)
        $ORIENTDB_HOME/bin/orientdb.sh logs  
        ;;
    status)
        $ORIENTDB_HOME/bin/orientdb.sh status  
        ;;
    -h|--help)
        usage
        exit 1
        ;;
    *) 
        echo "Error: Parameter error"
        exit 1
        ;;
esac

exit 0
