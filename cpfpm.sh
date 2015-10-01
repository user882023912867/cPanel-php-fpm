#!/bin/bash
## (C) sysally.net

cpfpm_uninstall(){

rm -f /var/cpanel/templates/apache2_4/vhost.local 
rm -f /var/cpanel/templates/apache2_4/ssl_vhost.local

rm -f /scripts/postwwwacct
rm -f /scripts/postkillacct

mv /scripts/postwwwacctorig /scripts/postwwwacct
mv /scripts/postkillacctorig /scripts/postkillacct
chkconfig php-fpm off
/etc/init.d/php-fpm stop

/scripts/rebuildhttpdconf
/scripts/restartsrv httpd
rm -rf /opt/cpfpm

echo -e '\e[45mI am not removing the extra options passed to easyapache \e[0m'
echo -e '\e[45mYou can find them in follwing files /var/cpanel/easy/apache/rawopts/Apache2_4 /var/cpanel/easy/apache/rawopts/all_php5\e[0m/'
echo -e '\e[45mPHP-FPM startup script and config files are also not removed /etc/init.d/php-fpm /usr/local/etc/php-fpm.conf /etc/logrotate.d/phpfpm\e[0m/'
echo -e '\e[45mYou may need to recompile Apache to use any other MPM other than event \e[0m'

}

cpfpm_install(){

proxy_fcgi=0
php_fpm=0

#Checking Apache for mod_proxy_fcgi
/usr/local/apache/bin/apachectl -l|grep mod_proxy_fcgi
if [ $? -eq 0 ]; then
	echo -e '\e[93mmod_proxy_fcgi : OK \e[0m'
else
	proxy_fcgi=1
fi

#Checking PHP for PHP-FPM 
php-config --configure-options|grep "enable-fpm"
if [ $? -eq 0 ];then
	echo -e '\e[93m PHP-FPM support : OK \e[0m'
else
	php_fpm=1
fi

if [ ${proxy_fcgi} -eq 1 -o ${php_fpm} -eq 1 ];then
	#Add custom compile options to Apache and PHP
	if [ -f /var/cpanel/easy/apache/rawopts/all_php5 ];then
		grep 'enable-fastcgi' /var/cpanel/easy/apache/rawopts/all_php5 || echo '--enable-fastcgi' >> /var/cpanel/easy/apache/rawopts/all_php5
		grep 'enable-fpm' /var/cpanel/easy/apache/rawopts/all_php5  || echo '--enable-fpm' >> /var/cpanel/easy/apache/rawopts/all_php5
	else
		echo '--enable-fastcgi' >> /var/cpanel/easy/apache/rawopts/all_php5
		echo '--enable-fpm' >> /var/cpanel/easy/apache/rawopts/all_php5
	fi
	if [ -f /var/cpanel/easy/apache/rawopts/Apache2_4 ];then 
		grep 'enable-proxy-fcgi=static' /var/cpanel/easy/apache/rawopts/Apache2_4 || echo '--enable-proxy-fcgi=static' >> /var/cpanel/easy/apache/rawopts/Apache2_4
	else
		echo '--enable-proxy-fcgi=static' >> /var/cpanel/easy/apache/rawopts/Apache2_4
	fi
	echo -e '\e[45mRecompile Apache and PHP using EasyApache \e[0m'
	echo -e '\e[45mYou should choose Apache 2.4 \e[0m'
	echo -e '\e[45mEnable EVENT MPM for performance \e[0m'
	echo -e '\e[45mDo NOT build php as apache module as this is not thread safe and event MPM is threaded \e[0m'
	echo -e '\e[45mOnce EasyApache is complete with above options rerun this script again with install option selected to complete cpfpm installation \e[0m'
else 
	echo -e '\e[93mProceeding with cpfpm setup\e[0m'
	mkdir -p /var/run/php-fpm
	mkdir -p /opt/cpfpm
	mkdir -p /opt/cpfpm/php-fpm.pool.d
	mkdir -p /opt/cpfpm/defaultconfs
	mkdir -p /opt/cpfpm/scripts
	wget -O /opt/cpfpm/defaultconfs/php-fpm.service.default https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/php-fpm.service.default
	wget -O /opt/cpfpm/defaultconfs/init.d.php-fpm https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/init.d.php-fpm
	wget -O /opt/cpfpm/defaultconfs/php-fpm.pool.default https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/php-fpm.pool.default
	wget -O /usr/local/etc/php-fpm.conf.default https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/php-fpm.conf.default
	

	echo -e '\e[93mAdding Custom Apache templates\e[0m'
	wget -O /opt/cpfpm/defaultconfs/proxypassphp.include https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/proxypassphp.include
	cp -p /var/cpanel/templates/apache2_4/vhost.default /var/cpanel/templates/apache2_4/vhost.local
	cp -p /var/cpanel/templates/apache2_4/ssl_vhost.default /var/cpanel/templates/apache2_4/ssl_vhost.local
	sed -i '/DocumentRoot/ r /opt/cpfpm/defaultconfs/proxypassphp.include' /var/cpanel/templates/apache2_4/vhost.local
	sed -i '/DocumentRoot/ r /opt/cpfpm/defaultconfs/proxypassphp.include' /var/cpanel/templates/apache2_4/ssl_vhost.local

	echo -e '\e[93mSetting up cpanel hooks\e[0m'
	wget -O /opt/cpfpm/scripts/setfpmpool https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/setfpmpool
	wget -O /opt/cpfpm/scripts/setredis   https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/setredis
	wget -O /opt/cpfpm/scripts/delfpmpool https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/delfpmpool
	wget -O /opt/cpfpm/scripts/delredis   https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/delredis
	chmod +x /opt/cpfpm/scripts/*
	if [ -f /scripts/postwwwacct ];then
		mv /scripts/postwwwacct /scripts/postwwwacctorig
	fi
	wget -O /scripts/postwwwacct https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/postwwwacct
	chmod a+x /scripts/postwwwacct

	if [ -f /scripts/postkillacct ];then
		mv /scripts/postkillacct /scripts/postkillacctorig
	fi
	wget -O /scripts/postkillacct https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/postkillacct	
	chmod a+x /scripts/postkillacct
	wget -O /etc/logrotate.d/phpfpm https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/php-fpm.logrotate.default

        echo -e '\e[93mInstalling GeoIP module\e[0m'
        yum -y install GeoIP*
        wget -qO - https://github.com/maxmind/geoip-api-mod_geoip2/archive/1.2.10.tar.gz | tar -xzp && cd geoip-*
        apxs -i -L/usr/lib64 -I/usr/include -lGeoIP -c mod_geoip.c

        echo -e '\e[93mAdding Custom Apache includes\e[0m'
	wget -O /etc/httpd/conf/includes/pre_main_global.conf https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/pre_main_global.conf
        SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
        USER_IP=$(last -i | grep "root.*still logged in" | awk '{print $3}')
        USER_GEOIP=$(geoiplookup ${USER_IP} | awk {'print $4'})
        sed -i "s/MYCOUNTRY/${USER_GEOIP//,/}/" /etc/httpd/conf/includes/pre_main_global.conf
        sed -i "s/MYIPADDRESS/${USER_IP}/" /etc/httpd/conf/includes/pre_main_global.conf
        
	echo -e '\e[93mInitializing FPM pools and rebuilding Apache conf\e[0m'
	for CPANELUSER in $(cat /etc/domainusers|cut -d: -f1)
	do
		/opt/cpfpm/scripts/setfpmpool ${CPANELUSER}
	done
	
	/scripts/rebuildhttpdconf
	/scripts/restartsrv httpd
	
	echo -e '\e[45mcpfpm installation complete\e[0m'	
	echo -e '\e[45mFor more info please refer\e[0m - http://wiki.apache.org/httpd/PHP-FPM '	
fi
}

if [ $# -ne 1 ]
then
        echo "usage $0 COMMAND"
	echo "COMMAND:"
	echo " install - Install cpfpm"
	echo " uninstall - Uninstall cpfpm"
	echo " help - Usage Instructions for this script"
        exit 1
else
	case "$1" in
	install)
		cpfpm_install
		;;
	uninstall)
		cpfpm_uninstall
		;;
	help)
		echo "usage $0 COMMAND"
        	echo "COMMAND:"
        	echo " install - Install cpfpm"
        	echo " uninstall - Uninstall cpfpm"
        	echo " help - Usage Instructions for this script"
        	exit 0
		;;
	*)
		echo "Unknown COMMAND"
		echo "run $0 help"
		exit 1
		;;
	esac
fi
