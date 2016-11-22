#!/bin/sh
CONF=$CONF
RENEW=$RENEW
MAIN_HOST=$HOST
LOG="/logs/startup.log"


if [ ! -d "/code" ]; then
	echo "please checkout tuanduimao source code, first. ( nginx may not work) " >> $LOG
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
if [ "$ug" != "www-data:www-data" ]; then
	chown -R www-data:www-data /data 
fi

# ug=$(ls -l /code | awk '{print $3":"$4}')
# if [ "$ug" != ":$GROUP" ]; then
# 	chown -R $USER:$GROUP /code 
# fi

# 更新配置文件
if [ -z $CONF ]; then
	CONF="default"
fi

if [ ! -d "/defaults/config/$CONF" ]; then
	CONF="default"
	echo "$CONF not exist. default selected!" >> $LOG
fi

if [ ! -d "/config/nginx" ]; then
	cp -r "/defaults/config/$CONF/nginx" /config/
fi

if [ ! -d "/config/php" ]; then
	cp -R "/defaults/config/$CONF/php" /config/
fi

if [ ! -d "/config/lua" ]; then
	cp -R "/defaults/config/$CONF/lua" /config/
fi


# copy php.ini 
if [ -f "/config/php/php.ini" ]; then
	cp -f /config/php/php.ini  /opt/php7/etc/php.ini
fi

# copy route.lua
if [ ! -f "/code/route.lua" ]; then
	cp -f /config/lua/route.lua  /code/route.lua
fi

# copy route.rewrite.conf
if [ ! -f "route.rewrite.conf" ]; then
	cp -f /config/nginx/route.rewrite.conf  /code/route.rewrite.conf
fi



# 创建服务配置目录 (可写目录)
if [ ! -d "/config/service" ]; then
	mkdir -p "/config/service"
	chown -R www-data:www-data /config/service
fi


# fix vhost 
if [ "$MAIN_HOST" != "tuanduimao.lc" ]; then

	if [ -f "/config/nginx/vhost/tuanduimao.lc" ]; then
		cp /config/nginx/vhost/tuanduimao.lc "/config/nginx/vhost/$MAIN_HOST"
		sed -i "s/tuanduimao.lc/$MAIN_HOST/g" "/config/nginx/vhost/$MAIN_HOST"
	fi
fi


# xdebug logs
if [ ! -d "/logs/xdebug" ]; then
	mkdir /logs/xdebug
fi

# 创建默认目录
if [ ! -d "/run/nginx" ]; then
	mkdir /run/nginx
fi

if [ ! -d "/run/php" ]; then
	mkdir -p /run/php/fpm
fi

if [ ! -d "/logs/php" ]; then
	mkdir -p /logs/php/fpm
fi

if [ ! -d "/logs/nginx" ]; then
	mkdir -p /logs/nginx/fpm
fi

if [ ! -d "/data/stor/public" ]; then
	mkdir -p /data/stor/public
	chown -R www-data:www-data /data/stor
fi

if [ ! -d "/data/stor/private" ]; then
	mkdir -p /data/stor/private
	chown -R www-data:www-data /data/stor
fi

if [ ! -d "/data/composer" ]; then
	mkdir -p /data/composer
	chown -R www-data:www-data /data/composer
fi


# 启动 PHP-FPM
/opt/php7/sbin/php-fpm -c /config/php/php.ini  -y /config/php/fpm/php-fpm.conf

# 启动 Nginx
/opt/openresty/nginx/sbin/nginx -c /config/nginx/nginx.conf

# 安装 composer
if [ ! -f "/data/composer/composer.lock" ]; then
	/bin/tdm composer
fi

# 保持运行状态
/usr/bin/tail -f /dev/null
