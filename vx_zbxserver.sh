#! /bin/bash
#set -x
# ****************************************************************************
# *
# * Author:           	(c) 2004-2023  Cybionet - Ugly Codes Division
# *
# * File:               vx_zbxserver.sh
# * Version:            0.1.14
# *
# * Description:        Zabbix Server LTS installation script under Ubuntu LTS Server.
# *
# * Creation: October 03, 2014
# * Change:   August 27, 2022
# *
# ****************************************************************************


#############################################################################################
# ## CUSTOM VARIABLES

# ## Force configuration of the script.
# ## Value: enabled (true), disabled (false).
isConfigured='false'

# ## # ## Choose the repository from which you want to install Zabbix Server (0=Zabbix Repo (recommended), 1=Distribution Repo).
installDefault=0

# ## Zabbix Server version.
# ## 3.x: 3.0, 3.2, 3.4
# ## 4.x: 4.0, 4.2, 4.5
# ## 5.x: 5.0, 5.5
# ## 6.x: 6.0
# ## 4.0, 5.0 and 6.0 are LTS version.
zbxVers='6.0'

# ## Local scripts location (Without the trailing slash).
scriptLocation='/opt/zabbix'

# ## Deployment URL.
declare -r urlDeploy='hub.cybionet.online'
#"https://github.com/cybiohub/svc_zabbixagent/archive/refs/heads/master.zip"

#############################################################################################
# ## VARIABLES

declare -r isConfigured
declare -ir installDefault
declare -r zbxVers
declare -r scriptLocation
declare -r urlDeploy

# ## Distribution: ubuntu, debian, raspian.
osDist=$(lsb_release -i | awk '{print $3}')
declare -r osDist

# ## Supported version.
# ## Ubuntu: focal, bionic, trusty.
# ## Debian: bulleye, buster, jessie, stretch.
# ## Raspbian: buster, stretch.
osVers=$(lsb_release -c | awk '{print $2}')
declare -r osVers

# ## Check PHP installed version.
phpVers=$(apt-cache policy php | grep Candidate | awk -F ":" '{print $3}' | awk -F "+" '{print $1}')
declare -r phpVers

# ## Zabbix Agent installation script URL.
urlZbxAgent='https://github.com/cybiohub/svc_zabbixagent/archive/refs/heads/master.zip'
declare -r urlZbxAgent

# ## LAMP installation script URL.
urlLAMP='https://github.com/cybiohub/svc_lamp/archive/refs/heads/master.zip'
declare -r urlLAMP


#############################################################################################
# ## VERIFICATION

# ## Check if the script is configured.
if [ "${isConfigured}" == 'false' ] ; then
  echo -n -e '\e[38;5;208mWARNING: Customize the settings to match your environment. Then set the "isConfigured" variable to "true".\n\e[0m'    
  exit 0
fi

# ## Check if the script are running under root user.
if [ "${EUID}" -ne 0 ]; then
  echo -n -e "\n\n\n\e[38;5;208mWARNING:This script must be run with sudo or as root.\e[0m"
  exit 0
fi

# ## Last chance. Ask before execute.
echo -n -e "\n\n\n\e[38;5;208mWARNING: You must have preinstalled script vx_lamp.sh before running this script.\e[0m"
echo -n -e "\n\e[38;5;208mWARNING:\e[0m You are preparing to install the Zabbix Server service. Press 'y' to continue, or any other key to exit: "
read -r ANSWER
if [ "${ANSWER,,}" != "y" ]; then
  echo "Have a nice day!"
  exit 0
fi

# ## Don't uses distribution repo message.
if [ ${installDefault} -eq 1 ]; then
  echo -e "Do you realy want to install the distribution Zabbix Server (Y/N) [default=N]?"
  echo -e "If not, change \"installDefault\" parameter to '0' in this script."
  read -r INSTALL
  if [ "${INSTALL,,}" != 'n' ]; then
    echo 'Good choice!'
    exit 0
  fi
fi

# ## Check if the PHP version is defined.
if [ -z "${phpVers}" ]; then
  echo -e "\e[31;1;208mInternal problem: PHP version not defined.\e[0m"
  exit 1
fi


#############################################################################################
# ## FUNCTIONS

function zx_base_check {
 checkPackage apache2
 sapache="${dependency}"

 #checkPackage php"${phpVers}"
 #sphp="${dependency}"

 #checkPackage mysql-server
 #smysql="${dependency}"


 # ## Check if LAMP services are installed.
 if [ "${sapache}" -eq 0 ]; then
   dlPath='/root/download'

   if [ ! -d "${dlPath}" ]; then
     mkdir "${dlPath}"
   fi

   cd "${dlPath}" || echo 'ERROR: An unexpected error has occurred.'
   wget -t 1 -T 5 https://${urlDeploy}/services/apache2/vx_lamp.sh -O vx_lamp.sh
   chmod 700 "${dlPath}"/vx_lamp.sh

   # ## Warn and exit if LAMP is not installed.
   #echo -n -e "\n\n\n\e[31;1;208mWARNING: Missing Apache, PHP or MySQL server. Please launch vx_lamp.sh script\e[0m.\n\n"
   echo -n -e "\n\n\n\e[31;1;208mWARNING: Missing Apache, PHP or MySQL server. Please install these dependancies\e[0m.\n\n"
   exit 0
 fi
}

# ## Checks for the presence of the package.
function checkPackage() {
 REQUIRED_PKG="${1}"
 if ! dpkg-query -s "${REQUIRED_PKG}" > /dev/null 2>&1; then
   dependency=0
 else
   dependency=1
 fi
}


# ## SYSTEM #################################################

# ## Basic packages.
function zx_base {
 # ## Packages needed for basic script in Zabbix Server.
 apt-get -y install fping
 apt-get -y install nmap
 apt-get -y install traceroute

 # ## --with-ssh2
 apt-get -y install openssh-server
 apt-get -y install libssh2-1-dev
 apt-get -y install libcurl4-openssl-dev

 # ## --with-openipmi
 apt-get -y install openipmi libopenipmi-dev libopenipmi0
 
 # ## --with-net-snmp
 apt-get -y install snmpd snmp
 apt-get -y install libsnmp-dev
 apt-get -y install snmp-mibs-downloader # ## Not supported on Debian.

 apt-get -y install libiksemel-dev
 apt-get -y install libpq-dev

 # ## --with-ldap
 apt-get -y install libldap2-dev

 # ## --with-java
 apt-get -y install openjdk-9-jdk # ## openjdk-8-jdk on Debian.

 # ## --with--unixodbc
 apt-get -y install unixodbc unixodbc-dev unixodbc-bin

 # ## --with--jabber
 # apt-get -y install ejabberd

 # ## Dependencies required for the Zabbix server.
 apt-get -y install libiksemel3 libltdl7
 apt-get -y install odbc-postgresql tdsodbc libodbc1
}

# ## Added Zabbix repository.
function zxRepo {
 if [ ! -f '/etc/apt/sources.list.d/zabbix.list' ]; then
   echo -e "# ## Zabbix ${zbxVers} Repository" > /etc/apt/sources.list.d/zabbix.list
   echo -e "deb https://repo.zabbix.com/zabbix/${zbxVers}/${osDist,,}/ ${osVers} main contrib non-free" >> /etc/apt/sources.list.d/zabbix.list
   echo -e "deb-src https://repo.zabbix.com/zabbix/${zbxVers}/${osDist,,}/ ${osVers} main contrib non-free" >> /etc/apt/sources.list.d/zabbix.list

   apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-keys 082AB56BA14FE591
   apt-get update
 else
   echo -e 'INFO: Source file already exist!'
 fi
}

# ## Installing the Zabbix Server with MySQL support.
function zxServer {
 apt-get -y install zabbix-server-mysql
 systemctl enable zabbix-server.service
}

# ## Download optimal Zabbix Server configuration.
function zxServerConfig {
 if [ -f '/etc/zabbix/zabbix_server.conf' ]; then
   mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.ori
 fi

 cp configs/zabbix_server.conf /etc/zabbix/
}


# ## FRONTEND ###############################################

# ## Installing the Zabbix interface.
function zxFrontend {
 apt-get -y install zabbix-frontend-php
 apt-get -y install ttf-dejavu-core
 apt-get -y install php"${phpVers}"-bcmath php"${phpVers}"-mbstring php"${phpVers}"-gd

 if [ -f '/etc/apache2/conf-available/zabbix-frontend-php.conf' ]; then
   a2enconf zabbix-frontend-php.conf
 fi

 systemctl reload apache2
}

## # A TERMINER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
function zx_frontend_tls {
 mkdir /etc/ssl/zabbix/
 sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out /etc/ssl/zabbix/zabbix.crt -keyout /etc/ssl/zabbix/zabbix.key
}

# ## Installing the Zabbix Agent.
function zx_agent {
 apt-get install -y zabbix-agent
}

# ## Installing Zabbix tools (Included in Zabbix Agent 4.x and more from Zabbix Repo).
function zxTools {
 apt-get install -y zabbix-get
 apt-get install -y zabbix-sender
}

# ## Installation of the Java gateway.
function zx_javagw {
 apt-get install -y zabbix-java-gateway
}

# ## MySQL database (Installed with the vx_lamp.sh script).
function zx_mysql {
 apt-get -y install mysql-server libmysqlclient-dev libmysqld-dev
 apt-get -y install zabbix-server-mysql
}

# ## Creating the Zabbix service user.
function zx_user {
 useradd -d /home/zabbix -s /bin/bash -c 'Zabbix Server' -m zabbix
 echo -n -e "\nZabbix user password. \n\n"
 passwd

 echo 'zabbix ALL=(ALL) NOPASSWD:/usr/bin/nmap' >> /etc/sudoers.d/zabbix
}

# ## Creation of additional directories required.
function zxDir {
 if [ ! -d "${scriptLocation}" ]; then
   mkdir -p "${scriptLocation}"/{externalscripts,alertscripts}
   chown -R zabbix:zabbix "${scriptLocation}"/
 fi

 if [ ! -d '/var/run/zabbix/' ]; then
   mkdir -p '/var/run/zabbix/'
   chown -R zabbix:zabbix /var/run/zabbix/
 fi

 if [ ! -d '/var/log/zabbix-agent/' ]; then
   mkdir -p '/var/log/zabbix/'
   chown -R zabbix:zabbix /var/log/zabbix/
 fi
}

# ## PHP8.X configuration.
function cfg_php {
 sed -i -e 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/post_max_size = 8M/post_max_size = 32M/g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/max_input_time = 60/max_input_time = 600/g' /etc/php/"${phpVers}"/apache2/php.ini
}


#############################################################################################
# ## EXECUTION

# ## Installation of the basic packages required for Zabbix server.
zx_base_check
zx_base

# ## Installation of the dependencies required to Zabbix server under Ubuntu.
if [ "${installDefault}" -eq 0 ]; then
  # ## Added Zabbix repository as per setting.
  zxRepo
  zxServer
else
 # ## Installing Zabbix Server.
 zxServer
fi

# ## Creation of the necessary directories for Zabbix.
zxDir

# ## Installing frontend for Zabbix.
zxFrontend
zx_frontend_tls

# ## Copy of the ready-to-use simplified configuration file.
zx_server_cfg

# ## Adjusting the PHP configuration.
cfg_php

# ## Creating the Zabbix user.
zx_user

# ## Restart the Apache service.
systemctl restart apache2.service

# ## MySQL database (Unused: Installed with vx_lamp.sh).
# zx_mysql

# ##############
# ## EXTRA

# ## Installing the Zabbix Agent.
#zx_agent

# ## Installation of the Java gateway.
#zx_javagw

# ## Installing Zabbix tools (Included in Zabbix Agent 4.x and more from Zabbix Repo).
if [ "${installDefault}" -eq 1 ]; then
  zxTools
fi

# AJOUTER UN READ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo -n -e "\n\n\n\e[38;5;208mPlease create database manually.\e[0m\n"
echo -e "mysql -p -e \"create database zabbix character set utf8 collate utf8_bin;\""
echo -e "mysql -p -e \"grant all on zabbix.* to 'zabbix'@'localhost' identified by 'SECRETPASSWORD';\""
echo -e "exit;\n"
echo -e "\nPour une version depot Zabbix:\n"
echo -e "zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -p zabbix\n"
echo -e "\nPour une version Ubuntu/Debian:\n"
echo -e "zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql -u zabbix -p zabbix\n"
echo -e "zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql -u zabbix -p zabbix\n"
echo -e "zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql -u zabbix -p zabbix\n"
echo -e "\nAccess http://W.X.Y.Z/zabbix/ to finish configuration.\n"
# ##echo -e "\nCopy configuration file in /usr/share/zabbix/conf/ directory.\n"

echo -e "\n\nDefault information\nUser: Admin \nPassword: zabbix\n"


# ## Exit.
exit 0

# ## END
