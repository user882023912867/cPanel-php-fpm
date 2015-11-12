# cPanel-php-fpm + redis setup per account

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
<br/>
wget https://raw.githubusercontent.com/magenx/cPanel-php-fpm/master/cpfpm.sh<br/>
chmod +x cpfpm.sh<br/>
./cpfpm.sh install<br/>

<br/><br/>
Convert mysql users from @localhost to @127.0.0.1:
```
for user in $(mysql -e 'select user,host from mysql.user' | grep localhost | awk {'print $1'})
do
mysql -e "RENAME USER "${user}"@"localhost" TO "${user}"@"127.0.0.1";"
done
```
