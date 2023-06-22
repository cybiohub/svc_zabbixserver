#! /bin/bash
#set -x
# ****************************************************************************
# *
# * Author:             (c) 2004-2022  Cybionet - Ugly Codes Division
# *
# * File:               zbxserverchecker.sh
# * Version:            0.0.17
# *
# * Description:        This script checks if the zabbix_server service is functional.
# *                     Otherwise, it sends an alert in the desired format.
# *
# * Creation: August 29, 2007
# * Change:   August 27, 2022
# *
# ****************************************************************************
# *
# * chown root:root zbxserverchecker.sh
# * chmod 500 zbxserverchecker.sh
# * mv zbxserverchecker.sh /opt/zabbix/checker
# *
# * Add the following value to the crontab.
# *
# * vim /etc/cron.d/zbxserverchecker
# *
# * # Zabbix Server Checker
#   */10 * * * * root /opt/zabbix/checker/zbxserverchecker.sh >/dev/null 2>&1
# *
# *
# * Note:
# *
# * Required to use email. Why mutt? Because it work with Outlook 365.
# *   apt-get install mutt
# *
# * Required if you want to use SMS.
# *   apt-get install smsclient
# *
# ****************************************************************************


#####################################################################
# ## CONFIGURATION

# ## shellcheck source=/etc/zabbix/zbxservercheck.conf
source /etc/zabbix/zbxservercheck.conf


# ############################################################
# ## VARIABLES


readonly version='0.0.17' # <============================FAIRE QUELQUE CHOSE AVEC CASE.

readonly APPMAIL='/usr/bin/mutt'

DATE=$(date +%Y-%m-%d%n%H:%M:%S%n)


# ############################################################
# ## LANGUAGE

# ## Subject of the message.
  SUBJECT="Zabbix - Alerte du service Agent Zabbix ${HOSTNAME}"

# ## Error messages.
  MESSAGE1="Redemarrage du service zabbix_server sur ${HOSTNAME}"
  MESSAGE2="Le service Agent Zabbix sur ${HOSTNAME} ne repond plus."
  MESSAGE3="Le serveur Agent Zabbix de ${HOSTNAME} a un probleme de configuration."
  MESSAGE5="Trouble de connectivite (externe) sur ${HOSTNAME}."
  MESSAGE6="Erreur critique sur l'Agent Zabbix. Une intervention est nécessaire"
  MESSAGE7="Le service Zabbix server sur ${HOSTNAME} est défunts."
  MESSAGE8="Le service Zabbix server sur ${HOSTNAME} a démarré correctement."


# #################################################################
# Function Declaration (Do not change anything under this section).
# #################################################################

# ############################################################
# ## FUNCTIONS

# ############################################################
# ## MEDIA (Email, SMS, LOG)

email() {
 # ## Building a message to send under Ubuntu / Debian.
 echo -e "${HOSTNAME}: ${MESSAGE} \n\n${DATE}\n" > zbxserver_check.err

 # ## Sends email via Ubuntu / Debian.
#cat zbxserver_check.err | /usr/bin/mail -s "${SUBJECT}" "${TO}"
 /usr/bin/mail -s "${SUBJECT}" "${TO}" < zbxserver_check.err

 # ## Delete the temporary sending file.
 rm zbxserver_check.err
}

sms() {
 # ## Sends an SMS message.
 sms_client "${pagerFrom}" "${MESSAGE}"
}

log() {
 # ## Creating the location for the log if it does not exist.
 if [ ! -d "${LOG}" ]; then
   mkdir "${LOG}"
   chown "${LOG}" zabbix:zabbix
   chmod 664 "${LOG}"
 fi

 # ## Writing to a log file.
 echo "${DATE} ${MESSAGE}" >> "${LOG}/${logName}"
}

checkProcess() {
 # ## Verify if the zabbix_server service is working.
 STATUS=$(pgrep -c -x 'zabbix_server')

 # ## Attempt to reboot before sending an alarm.
 if [ "${STATUS}" -eq 0 ]; then
   MESSAGE="${MESSAGE2}"
   actions
   reset
 fi

 if [ "${STATUS}" -eq 0 ]; then
   MESSAGE="${MESSAGE6}"
   actions
 fi
}

defunctProcess() {
 # ## Verify if the zabbix_server service is not defunct.
 P_ITEM0=$(pgrep -c 'zabbix_server <defunct>')
 declare -i P_ITEM0

 # ## One child process died.
 #declare -i P_ITEM1=$(cat ${LOG}/${logName} | grep -c -i 'One child process died')

 #P_STATUS=$(($P_ITEM0+$P_ITEM1))
 P_STATUS=$((P_ITEM0))
 MESSAGE="${MESSAGE7}"

 # ## Attempt to reboot before sending an alarm.
 if [ "${P_STATUS}" -ne 0 ]; then
   actions
   reset
 fi

 if [ "${P_STATUS}" -ne 0 ]; then
   actions
 fi
}

checkConnectivity() {
 # ## Checks connectivity with remote host.
 if ! ping -c 1 "${REMOTE}" &> /dev/null 2>&1 ; then
   MESSAGE="${MESSAGE5}"
   actions
 fi
}

system() {
# ## BUG: SI IL Y A UNE ERREUR DANS LE LOG CETTE CETTE SECTION RESTE TOUJOURS ACTIVE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 # ## Can't find shared memory for database cache.
 S_ITEM0=$(<"${LOG}/zabbix_server.log" grep -c -i 'Listener failed with error')
 declare -i S_ITEM0

 # ## Listener failed with error.
 S_ITEM1=$(grep -c -i 'Listener failed with error' < /var/log/zabbix/zabbix_server.log)
 declare -i S_ITEM1

 S_STATUS=$((S_ITEM0+S_ITEM1))
 MESSAGE="${MESSAGE3}"

 # ## Zabbix service configuration problem.
 if [ "${S_STATUS}" -eq 0 ]; then
   actions
 fi
}

actions() {
 # ## Uncomment the actions you want (log, email, sms).
 log
 email
 #sms
}

reset() {
 # ## Resetting the zabbix_server service.
 systemctl stop zabbix-server.service
 if [ -f '/var/run/zabbix/zabbix_server.pid' ]; then
   rm /var/run/zabbix/zabbix_server.pid
 fi
 systemctl start zabbix-server.service

 # ## Added an entry in the log.
 MESSAGE="${MESSAGE1}"
 actions

 # ## Recheck the status of the zabbix_server service.
 STATUS=$(pgrep -c -x 'zabbix_server')

 # ## Attempt to reboot before sending final alarm.
 if [ "${STATUS}" -eq 0 ]; then
   MESSAGE="${MESSAGE6}"
   actions
 else
   MESSAGE="${MESSAGE8}"
   actions
 fi
}


# ############################################################
# ## EXECUTION

# ## Check the Zabbix service.
checkProcess

# ## Additional verification for Zabbix service.
defunctProcess

# ## Check connectivity (Google by default).
checkConnectivity

# ## Experimental.
#system

# ## Exit.
exit 0

# ## END
