#! /bin/bash
#set -x
# ****************************************************************************
# *
# * Author:             (c) 2004-2023  Cybionet - Ugly Codes Division
# *
# * File:               install.sh
# * Version:            1.1.25
# *
# * Description:        Script to install environment for zabserverchecker.
# *
# * Creation: December 02, 2013
# * Change:   August 28, 2022
# *
# ****************************************************************************
# * chmod 500 install.sh
# ****************************************************************************

# #################################################################
# ## VARIABLES

# ## Do not put the trailing slash.
readonly scriptLocation='/opt/zabbix/checker'

# ## Actual date.
actualYear=$(date +"%Y")
declare -r actualYear

# ## Title header.
appHeader="(c) 2004-${actualYear}  Cybionet - Installation Wizard"
declare -r appHeader


#############################################################################################
# ## VERIFICATION

# ## Check if the script are running with sudo or under root user.
if [ "${EUID}" -ne 0 ] ; then
  echo -e "\n\e[34m${appHeader}\e[0m\n"
  echo -e "\n\n\n\e[33mCAUTION: This script must be run with sudo or as root.\e[0m"
  exit 0
else
  echo -e "\n\e[34m${appHeader}\e[0m"
  printf '%.s─' $(seq 1 "$(tput cols)")
fi

# ## Check if the script is configured.
isConfigured=$(cat ./etc/zbxserverchecker.conf | grep isConfigured | awk -F '=' '{print $2}' | sed 's/[[:punct:]]//g')

if [ "${isConfigured}" == 'false' ] ; then
  echo -n -e '\e[38;5;208mWARNING: Customize the configuration of the script to match your environment. Then set the "isConfigured" variable to "true" in configuration.\n\e[0m'
  exit 0
fi


# #################################################################
# ## FUNCTIONS

function cronJob() {
  chmod 644 ./cron.d/zbxserverchecker
  cp ./cron.d/zbxserverchecker /etc/cron.d/
}

function scriptDirectory() {
 # ## Create a location for the script if it does not exist.
 if [ ! -d "${scriptLocation}" ]; then
   mkdir -p "${scriptLocation}"
 fi
}

function copyScript() {
 echo -e "\t- Installing configuration file for the script."
 cp ./etc/zbxserverchecker.conf /etc/zabbix/

 echo -e "\t- Copy the script to ${scriptLocation} directory."
 chmod 500 ./bin/zbxserverchecker.sh
 cp ./bin/zbxserverchecker.sh /opt/zabbix/checker/
}

# #################################################################
# ## EXECUTION

echo -e "\e[32;1;208m[INFORMATION]\e[0m"

scriptDirectory
copyScript

cronJob

echo -e "\n\e[32;1;208m[COMPLETED]\e[0m"


# ## Exit.
exit 0

# ## END
