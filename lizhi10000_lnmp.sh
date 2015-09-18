#!/bin/bash
#
# author zengzhihai
# 1372712268@qq.com
# blog http://lizhi10000.com
# 
#
tmpCurrentDirectory=`pwd`
install_directory=/usr/local/lnmp
echo 
echo 
echo "Welome use lizhi10000 lnmp install. author by zengzhihai,and also called by 追麾~"
echo 
echo 
# delete some rpm soft
if [ `rpm -qa php` ];then
	rpm -e php
fi
if [ `rpm -qa mysql` ];then
	rpm -e mysql
fi
if [ `rpm -qa httpd` ];then
	rpm -e httpd
fi

read -p "please enter a directory,default $install_directory,then create directory below /usr/local:" tmp_install_directory
if [ $tmp_install_directory ];then
	install_directory=/usr/local/$tmp_install_directory
	mkdir -pv $install_directory
	if [ $? -eq 0 ];then
		echo $install_directory"  install directory created success"
		echo 
	fi
else
	mkdir -pv $install_directory
fi
echo "install nginx"
echo 
rm -rf $tmpCurrentDirectory/nginx-1.8.0.tar.gz*

#create mysql directory
mkdir -pv $install_directory/mysql
default_mysql_data_directory=/data0/mysql/data
read -p "please enter a mysql store directory,default $defaul_mysql_data_directory,then create directory $defaul_mysql_data_directory:" defaul_mysql_data_directory

if [ $default_mysql_data_directory ];then
        mkdir -pv $default_mysql_data_directory
        if [ $? -eq 0 ];then
                echo $default_mysql_data_directory"  mysql install data directory created success"
                echo
        fi
else
        mkdir -pv $default_mysql_data_directory
fi

#start update time
ntpdate -u asia.pool.ntp.org
yes | cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo
cat << EOF > /etc/sysconfig/clock
ZONE="Asia/Shanghai"
UTC=false
ARC=false
EOF
hwclock -w


# install some soft
yum -y -q groupinstall "Development Tools"
yum -y -q groupinstall "Development Libraries"
yum -y -q install wget autoconf automake bison bzip2 bzip2-devel curl curl-devel cmake cpp crontabs diffutils elinks e2fsprogs-devel expat-devel file flex freetype-devel gcc gcc-c++ gd glibc-devel glib2-devel gettext-devel gmp-devel icu kernel-devel libaio libtool-libs libjpeg-devel libpng-devel libxslt libxslt-devel libxml2 libxml2-devel libidn-devel libcap-devel libtool-ltdl-devel libc-client-devel libicu libicu-devel lynx zip zlib-devel unzip patch mlocate make ncurses-devel readline readline-devel vim-minimal sendmail pam-devel pcre pcre-devel openldap openldap-devel openssl openssl-devel pcre pcre-devel lrzsz

wget -q http://mirrors.sohu.com/nginx/nginx-1.8.0.tar.gz
if [ $? -eq 0 ];then
	tar -zxf $tmpCurrentDirectory/nginx-1.8.0.tar.gz
fi
#add nginx user
if [ -z `cat /etc/passwd|grep nginx` ];then
	groupadd -r nginx
	useradd -r -g nginx nginx
fi

cd $tmpCurrentDirectory/nginx-1.8.0
#create some directory
if [ ! -d "/var/tmp/nginx/client" ];then
	mkdir -p /var/tmp/nginx/client
fi
if [ ! -d "/var/tmp/nginx/proxy" ];then
	mkdir -p /var/tmp/nginx/proxy
fi
if [ ! -d "/var/tmp/nginx/fcgi" ];then
	mkdir -p /var/tmp/nginx/fcgi
fi
if [ ! -d "/var/tmp/nginx/uwsgi" ];then
	mkdir -p /var/tmp/nginx/uwsgi
fi
if [ ! -d "/var/tmp/nginx/scgi" ];then
	mkdir -p /var/tmp/nginx/scgi
fi
./configure \
--prefix=$install_directory/nginx/html \
--sbin-path=$install_directory/nginx/sbin/nginx \
--conf-path=$install_directory/nginx/etc/nginx.conf \
--error-log-path=$install_directory/nginx/log/error.log \
--http-log-path=$install_directory/nginx/log/access.log \
--pid-path=/var/run/nginx/nginx.pid  \
--lock-path=/var/lock/nginx.lock \
--user=nginx \
--group=nginx \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_stub_status_module \
--with-http_gzip_static_module \
--http-client-body-temp-path=/var/tmp/nginx/client \
--http-proxy-temp-path=/var/tmp/nginx/proxy \
--http-fastcgi-temp-path=/var/tmp/nginx/fcgi \
--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
--http-scgi-temp-path=/var/tmp/nginx/scgi \
--with-pcre 
#install
make && make install

cat << EOF > /etc/rc.d/init.d/nginx
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "\$NETWORKING" = "no" ] && exit 0

nginx="$install_directory/nginx/sbin/nginx"
prog=\$(basename \$nginx)

NGINX_CONF_FILE="$install_directory/nginx/etc/nginx.conf"

[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx

lockfile=/var/lock/subsys/nginx

make_dirs() {
# make required directories
user=\`nginx -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*--user=\([^ ]*\).*/\1/g' -\`
options=\`\$nginx -V 2>&1 | grep 'configure arguments:'\`
for opt in \$options; do
if [ \`echo \$opt | grep '.*-temp-path'\` ]; then
   value=\`echo \$opt | cut -d "=" -f 2\`
   if [ ! -d "\$value" ]; then
           # echo "creating" \$value
           mkdir -p \$value && chown -R \$user \$value
   fi
fi
done
}

start() {
[ -x \$nginx ] || exit 5
[ -f \$NGINX_CONF_FILE ] || exit 6
make_dirs
echo -n $"Starting \$prog: "
daemon \$nginx -c \$NGINX_CONF_FILE
retval=\$?
echo
[ \$retval -eq 0 ] && touch \$lockfile
return \$retval
}

stop() {
echo -n $"Stopping \$prog: "
killproc \$prog -QUIT
retval=\$?
echo
[ \$retval -eq 0 ] && rm -f \$lockfile
return \$retval
}

restart() {
configtest || return \$?
stop
sleep 1
start
}

reload() {
configtest || return \$?
echo -n $"Reloading \$prog: "
killproc \$nginx -HUP
RETVAL=\$?
echo
}

force_reload() {
restart
}

configtest() {
\$nginx -t -c \$NGINX_CONF_FILE
}

rh_status() {
status \$prog
}

rh_status_q() {
rh_status >/dev/null 2>\&1
}

case "\$1" in
start)
rh_status_q && exit 0
\$1
;;
stop)
rh_status_q || exit 0
\$1
;;
restart|configtest)
\$1
;;
reload)
rh_status_q || exit 7
\$1
;;
force-reload)
force_reload
;;
status)
rh_status
;;
condrestart|try-restart)
rh_status_q || exit 0
        ;;
*)
echo $"Usage: \$0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
exit 2
esac
EOF

chmod +x /etc/rc.d/init.d/nginx
chkconfig --add nginx
chkconfig nginx on
#start nginx 
service nginx start

#delete nginx
cd $tmpCurrentDirectory
rm -rf $tmpCurrentDirectory/nginx-1.8.0.tar.gz*
rm -rf $tmpCurrentDirectory/nginx-1.8.0*


#mysql install

cd $tmpCurrentDirectory
wget -q http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.44.tar.gz
if [ $? -eq 0 ];then
        tar -zxf $tmpCurrentDirectory/mysql-5.5.44.tar.gz
fi


groupadd mysql
useradd -r -g mysql mysql
cd $tmpCurrentDirectory/mysql-5.5.44

#cmake install mysql
cmake -DCMAKE_INSTALL_PREFIX=$install_directory/mysql \
-DMYSQL_UNIX_ADDR=$install_directory/mysql/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_DATADIR=$default_mysql_data_directory \
-DMYSQL_USER=mysql \
-DMYSQL_TCP_PORT=3306

make && make install

chown -R mysql:mysql $install_directory/mysql
chown -R mysql:mysql $default_mysql_data_directory

cd $install_directory/mysql
yes | cp $install_directory/mysql/support-files/my-medium.cnf /etc/my.cnf
echo

$install_directory/mysql/scripts/mysql_install_db \
--basedir=$install_directory/mysql \
--datadir=$default_mysql_data_directory \
--user=mysql

cat << EOF >> /etc/profile
PATH=\$PATH:\$HOME/bin:$install_directory/mysql/bin:$install_directory/mysql/lib
EOF
source /etc/profile

cp $install_directory/mysql/support-files/mysql.server /etc/init.d/mysql

chkconfig mysql --level 235 on
service mysql start

#delete mysql soure 
cd $tmpCurrentDirectory
rm -rf $tmpCurrentDirectory/mysql-5.5.44*
rm -rf $tmpCurrentDirectory/mysql-5.5.44.tar.gz*


#install php
cd $tmpCurrentDirectory
wget -q http://jaist.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar -zxf $tmpCurrentDirectory/libmcrypt-2.5.8.tar.gz
cd $tmpCurrentDirectory/libmcrypt-2.5.8
./configure && make && make install

cd $tmpCurrentDirectory
rm -rf $tmpCurrentDirectory/libmcrypt-2.5.8.tar.gz*
rm -rf $tmpCurrentDirectory/libmcrypt-2.5.8*

cd $tmpCurrentDirectory
wget -q http://cn2.php.net/distributions/php-5.4.45.tar.gz
tar -zxf $tmpCurrentDirectory/php-5.4.45.tar.gz
cd $tmpCurrentDirectory/php-5.4.45

./configure --prefix=$install_directory/php --with-mysql=$install_directory/mysql --with-openssl --enable-fpm --enable-sockets --enable-sysvshm  --with-mysqli=$install_directory/mysql/bin/mysql_config --enable-mbstring --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib-dir --with-libxml-dir=/usr --enable-xml  --with-mhash --with-mcrypt  --with-config-file-path=$install_directory/php/etc --with-config-file-scan-dir=$install_directory/php/etc/php.d --with-bz2 --with-curl=/usr

make && make install

yes | cp $tmpCurrentDirectory/php-5.4.45/php.ini-production $install_directory/php/etc/php.ini
yes | cp $tmpCurrentDirectory/php-5.4.45/sapi/fpm/init.d.php-fpm  /etc/rc.d/init.d/php-fpm
chmod +x /etc/rc.d/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on
yes | cp $install_directory/php/etc/php-fpm.conf.default $install_directory/php/etc/php-fpm.conf 
service php-fpm start
cd $tmpCurrentDirectory
rm -rf $tmpCurrentDirectory/php-5.4.45.tar.gz*
rm -rf $tmpCurrentDirectory/php-5.4.45*

cat << EOF > $install_directory/nginx/etc/fastcgi_params

fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  HTTPS              \$https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx;
fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;


EOF


cat << EOF > $install_directory/nginx/etc/nginx.conf
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    #                  '\$status \$body_bytes_sent "\$http_referer" '
    #                  '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  log/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.php index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        location ~ \.php\$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
            include        fastcgi_params;
        }

    }


    include vhost/*.conf;

}
EOF

cat > $install_directory/nginx/html/html/phpinfo.php << EOF
<?php
phpinfo();
EOF
service nginx reload

#install redis
cd $tmpCurrentDirectory;
wget -q http://download.redis.io/releases/redis-2.8.17.tar.gz
tar -zxvf $tmpCurrentDirectory/redis-2.8.17.tar.gz
cd $tmpCurrentDirectory/redis-2.8.17
make PREFIX=$install_directory/redis install
cp $tmpCurrentDirectory/redis-2.8.17/redis.conf $install_directory/redis/

echo "please visit http://`hostname`/phpinfo.php"

