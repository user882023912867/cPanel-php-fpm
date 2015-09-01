#!/bin/bash

cphstack_uninstall(){

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
rm -rf /opt/xstack/cphstack

echo -e '\e[45mI am not removing the extra options passed to easyapache \e[0m'
echo -e '\e[45mYou can find them in follwing files /var/cpanel/easy/apache/rawopts/Apache2_4 /var/cpanel/easy/apache/rawopts/all_php5\e[0m/'
echo -e '\e[45mPHP-FPM startup script and config files are also not removed /etc/init.d/php-fpm /usr/local/etc/php-fpm.conf /etc/logrotate.d/phpfpm\e[0m/'
echo -e '\e[45mYou may need to recompile Apache to use any other MPM other than event \e[0m'
echo -e '\e[45mFor technical support email- support@sysally.net\e[0m/'



}

cphstack_install(){

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

if [ $proxy_fcgi -eq 1 -o $php_fpm -eq 1 ];then
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
	echo -e '\e[45mOnce EasyApache is complete with above options rerun this script again with install option selected to complete cpHstack installation \e[0m'
	echo -e '\e[45mContact support@sysally.net for technical support \e[0m'
else 
	echo -e '\e[93mProceeding with cpHstack setup\e[0m'
	wget -O /etc/init.d/php-fpm http://sysally.net/cphstack/init.d.php-fpm
	chmod a+x /etc/init.d/php-fpm
	chkconfig php-fpm on
	mkdir /var/run/php-fpm
	mkdir -p /opt/xstack/cphstack
	mkdir /opt/xstack/cphstack/php-fpm.pool.d
	mkdir /opt/xstack/cphstack/defaultconfs
	mkdir /opt/xstack/cphstack/scripts
	wget -O /usr/local/etc/php-fpm.conf http://sysally.net/cphstack/php-fpm.conf.default
	service php-fpm restart

	
	echo -e '\e[93mAdding Custom Apache templates\e[0m'
	wget -O /opt/xstack/cphstack/defaultconfs/proxypassphp.include http://sysally.net/cphstack/proxypassphp.include
	cp -p /var/cpanel/templates/apache2_4/vhost.default /var/cpanel/templates/apache2_4/vhost.local
	cp -p /var/cpanel/templates/apache2_4/ssl_vhost.default /var/cpanel/templates/apache2_4/ssl_vhost.local
	sed -i '/DocumentRoot/ r /opt/xstack/cphstack/defaultconfs/proxypassphp.include' /var/cpanel/templates/apache2_4/vhost.local
	sed -i '/DocumentRoot/ r /opt/xstack/cphstack/defaultconfs/proxypassphp.include' /var/cpanel/templates/apache2_4/ssl_vhost.local
	wget -O /opt/xstack/cphstack/defaultconfs/php-fpm.pool.default http://sysally.net/cphstack/php-fpm.pool.default

	echo -e '\e[93mSetting up cpanel hooks\e[0m'
	wget -O /opt/xstack/cphstack/scripts/setfpmpool http://sysally.net/cphstack/setfpmpool.script
	wget -O /opt/xstack/cphstack/scripts/delfpmpool http://sysally.net/cphstack/delfpmpool.script
	chmod a+x /opt/xstack/cphstack/scripts/setfpmpool
	chmod a+x /opt/xstack/cphstack/scripts/delfpmpool
	if [ -f /scripts/postwwwacct ];then
		mv /scripts/postwwwacct /scripts/postwwwacctorig
	fi
	wget -O /scripts/postwwwacct http://sysally.net/cphstack/postwwwacct.script
	chmod a+x /scripts/postwwwacct

	if [ -f /scripts/postkillacct ];then
		mv /scripts/postkillacct /scripts/postkillacctorig
	fi
	wget -O /scripts/postkillacct http://sysally.net/cphstack/postkillacct.script	
	chmod a+x /scripts/postkillacct
	
	wget -O /etc/logrotate.d/phpfpm http://sysally.net/cphstack/php-fpm.logrotate.default

	echo -e '\e[93mInitializing FPM pools and rebuilding Apache conf\e[0m'

	for CPANELUSER in $(cat /etc/domainusers|cut -d: -f1)
	do
		/opt/xstack/cphstack/scripts/setfpmpool $CPANELUSER
	done
	/scripts/rebuildhttpdconf
	/scripts/restartsrv httpd
	

	#Tweaks
	sysctl -w net.core.somaxconn=4096
	grep "net.core.somaxconn" /etc/sysctl.conf || echo "net.core.somaxconn = 4096" >> /etc/sysctl.conf
	echo 'exe:/usr/local/sbin/php-fpm' >> /etc/csf/csf.pignore
	

	echo -e '\e[45mcpHstack installation complete\e[0m'	
	echo -e '\e[45mFor more info please refer\e[0m - http://wiki.apache.org/httpd/PHP-FPM '	
	
	echo -e '\e[45mFor technical support email\e[0m - support@sysally.net'	


fi
}


if [ $# -ne 1 ]
then
        echo "usage $0 COMMAND"
	echo "COMMAND:"
	echo " install - Install cpHstack"
	echo " uninstall - Uninstall cpHstack"
	echo " help - Usage Instructions for this script"
        exit 1
else
	case "$1" in
	install)
		cphstack_install
		;;
	uninstall)
		cphstack_uninstall
		;;
	help)
		echo "usage $0 COMMAND"
        	echo "COMMAND:"
        	echo " install - Install cpHstack"
        	echo " uninstall - Uninstall cpHstack"
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
