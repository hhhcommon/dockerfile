#!/bin/sh
CONF=$CONF
RENEW=$RENEW
MASTER=$MASTER
CNAME="sentinel"
LOG="/logs/shell.log"

# 是否开启 RENEW
if [ ! -z "$RENEW" ]; then
	rm -rf /config/*
fi

# 检查用户组
ug=$(ls -l /config | awk '{print $3":"$4}')
if [ "$ug" != "root:root" ]; then
	chown -R root:root /config 
fi

ug=$(ls -l /logs | awk '{print $3":"$4}')
if [ "$ug" != "root:root" ]; then
	chown -R root:root /logs 
fi

ug=$(ls -l /data | awk '{print $3":"$4}')
if [ "$ug" != "root:root" ]; then
	chown -R root:root /data 
fi


# 更新配置文件
if [ -z $CONF ]; then
	CONF="default"
fi

if [ -z $MASTER ]; then
	MASTER="server"
	CNAME="redis"
fi

if [ ! -d "/defaults/config/$CONF" ]; then
	CONF="default"
	echo "$CONF not exist. default selected!" >> $LOG
fi

if [ ! -f "/config/redis.conf" ]; then
	cp -r "/defaults/config/$CONF/redis.conf" /config/
fi

if [ ! -f "/config/sentinel.conf" ]; then
	cp -r "/defaults/config/$CONF/sentinel.conf" /config/
fi

if [ ! -d "/logs/redis" ]; then
	mkdir /logs/redis
fi
 
"/usr/local/bin/redis-$MASTER" "/config/$CNAME.conf" >> $LOG

# 保持运行状态
/usr/bin/tail -f /dev/null