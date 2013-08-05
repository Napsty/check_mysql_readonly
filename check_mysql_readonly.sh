#!/bin/bash
#########################################################################
# Script:       check_mysql_readonly.sh                                 #
# Author:       Claudio Kuenzler www.claudiokuenzler.com                #
# Description:  Check if a mysql server running as slave is read only   #
# History:      20130805 Programmed script                              #
#########################################################################
# Usage: ./check_mysql_readonly -H dbhost -u dbuser -p dbpass
#########################################################################
help="\n$0 (c) 2013 Claudio Kuenzler published under GNU GPLv2 licence
Usage: $0 -H host -u username -p password\n
Options:\n-H Hostname or IP of slave server\n-u Username of DB-user\n-p Password of DB-user})\n"

STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning (not really used)
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
PATH=/usr/local/bin:/usr/bin:/bin # Set path

for cmd in mysql awk grep [ 
do
 if ! `which ${cmd} &>/dev/null`
 then
  echo "UNKNOWN: This script requires the command '${cmd}' but it does not exist; please check if command exists and PATH is correct"
  exit ${STATE_UNKNOWN}
 fi
done

# Check for people who need help - aren't we all nice ;-)
#########################################################################
if [ "${1}" = "--help" -o "${#}" = "0" ]; 
        then 
        echo -e "${help}";
        exit 1;
fi

# Important given variables for the DB-Connect
#########################################################################
while getopts "H:u:p:h" Input;
do
        case ${Input} in
        H)      host=${OPTARG};;
        u)      user=${OPTARG};;
        p)      password=${OPTARG};;
        h)      echo -e "${help}"; exit 1;;
        \?)     echo "Wrong option given. Please use options -H for host, -P for port, -u for user and -p for password"
                exit 1
                ;;
        esac
done

# Connect to the DB server and check for informations
#########################################################################
# Check whether all required arguments were passed in
if [ -z "${host}" -o -z "${user}" -o -z "${password}" ];then
        echo -e "${help}"
        exit ${STATE_UNKNOWN}
fi

# Connect to the DB server and get variables
isslave=$(mysql -h ${host} -u ${user} --password=${password} -N -e "show global status WHERE Variable_name='Slave_running'" | awk '{print $2}')
readonly=$(mysql -h ${host} -u ${user} --password=${password} -N -e "show global variables WHERE Variable_name='read_only'" | awk '{print $2}')

if [[ $isslave = "OFF" ]]
then 
  if [[ $readonly = "OFF" ]]
  then echo "MySQL Master is writable - all ok"; exit 0
  else echo "MySQL Master is set to read only"; exit 2
  fi
else
  if [[ $readonly = "OFF" ]]
  then echo "MySQL Slave is writable - critical"; exit 2
  else echo "MySQL Slave is set to read only - all ok"; exit 0
  fi
fi
