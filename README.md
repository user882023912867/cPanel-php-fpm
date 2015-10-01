# cPanel-php-fpm + redis setup per account
./cpfpm.sh install


CentOS 6<br/>
CentOS 7

<br/>
install redis<br/>
**CentOS 6**<br/>
rpm -Uhv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm<br/>
rpm -Uhv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm<br/>
yum -y --enablerepo=remi install redis<br/>
<br/>
**CentOS 7**<br/>
yum -y install epel-release<br/>
rpm -Uhv http://rpms.famillecollet.com/enterprise/remi-release-7.rpm<br/>
yum -y --enablerepo=remi install redis<br/>
