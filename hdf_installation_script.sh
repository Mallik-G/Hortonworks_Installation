
#################################################################################################################
#
#   Hortonworks DataFlow (HDF 3.0)
#
#   Installation & Config
#
#   https://docs.hortonworks.com/HDPDocuments/HDF3/HDF-3.0.0/bk_installing-hdf/content/ch_install-ambari.html
#
#   Test on: CentOS Linux release 7.2.1511 (Core) 
#
#################################################################################################################

'''
export HDF_HOST="172.26.202.185"
export HDP1_HOST="172.26.202.186"
export HDP2_HOST="172.26.202.187"
export HDP3_HOST="172.26.202.188"

ssh -i ~/.ssh/field.pem centos@172.26.202.185
ssh -i ~/.ssh/field.pem centos@172.26.202.186
ssh -i ~/.ssh/field.pem centos@172.26.202.187
ssh -i ~/.ssh/field.pem centos@172.26.202.188
'''

#################################################################################################################
#
#   Configure HDF
#
#################################################################################################################

ssh -i ~/.ssh/field.pem centos@172.26.202.185

export HDF_HOST="172.26.202.185"

# Update Centos
sudo yum -y update
sudo yum install -y wget

# Setup password-less SSH
ssh-keygen
cat ~/.ssh/id_rsa.pub >> authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Enable NTP 
sudo yum install -y ntp
sudo systemctl is-enabled ntpd
sudo systemctl enable ntpd
sudo systemctl start ntpd

# Update /etc/hosts/ file
sudo sh -c "echo $HDF_HOST $HOSTNAME $HOSTNAME.field.hortonworks.com >> /etc/hosts"

echo 'Printing hostname...'
sleep 3
hostname -f

# Edit the Network Configuration File
sudo sh -c "echo HOSTNAME=$HOSTNAME.field.hortonworks.com >> /etc/sysconfig/network"

# Temporarily Disable Firewall
sudo systemctl disable firewalld
sudo service firewalld stop

# Download Ambari Repo and Setup Ambar Server
sudo wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
sudo yum repolist
sudo yum install -y ambari-server
sudo echo -e "y\nn\n1\ny\nn" | sudo ambari-server setup
sudo ambari-server start

# Install MySQL
sudo yum install -y mysql-connector-java*
sudo ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
sudo yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
sudo yum install -y mysql-community-server
sudo systemctl start mysqld.service
grep 'A temporary password is generated for root@localhost' /var/log/mysqld.log |tail -1   # This command should output a temporary password.
sudo /usr/bin/mysql_secure_installation  # Enter the password, generated in the previous step.

# Setup MySQL Database and Users 
# For Streaming Analytics Manager and Schema Registry

mysql -u root -p  # Enter the new MySQL password that was created in the previous step.

create database registry;
create database streamline;

echo "Change the MySQL password IDENTIFIED BY, show in the next two lines"
sleep 15

CREATE USER 'registry'@'%' IDENTIFIED BY 'xxx';
CREATE USER 'streamline'@'%' IDENTIFIED BY 'xxx';

GRANT ALL PRIVILEGES ON registry.* TO 'registry'@'%' WITH GRANT OPTION ;
GRANT ALL PRIVILEGES ON streamline.* TO 'streamline'@'%' WITH GRANT OPTION ;

commit;

# Setup MySQL Database and Users 
# For Druid and Superset

CREATE DATABASE druid DEFAULT CHARACTER SET utf8;
CREATE DATABASE superset DEFAULT CHARACTER SET utf8;

echo "Change the MySQL password IDENTIFIED BY, show in the next two lines"
sleep 15

CREATE USER 'druid'@'%' IDENTIFIED BY 'xxx';
CREATE USER 'superset'@'%' IDENTIFIED BY 'xxx';

GRANT ALL PRIVILEGES ON *.* TO 'druid'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'superset'@'%' WITH GRANT OPTION;

commit;

exit

# Install HDF Management Pack
sudo ambari-server stop
wget http://public-repo-1.hortonworks.com/HDF/centos7/3.x/updates/3.0.0.0/tars/hdf_ambari_mp/hdf-ambari-mpack-3.0.0.0-453.tar.gz -O /tmp/hdf-ambari-mpack-3.0.0.0-453.tar.gz
sudo ambari-server install-mpack --mpack=/tmp/hdf-ambari-mpack-3.0.0.0-453.tar.gz --verbose
sudo ambari-server start

# Open up Ambari and continue with Browser-based installation
echo http://$HOSTNAME:8080
