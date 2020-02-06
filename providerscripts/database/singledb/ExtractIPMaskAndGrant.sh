
if ( [ ! -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:MySQL ] && [ ! -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:Maria ] )
then
   exit
fi

DB_N="`/bin/sed '1q;d' ${HOME}/credentials/shit`"
DB_P="`/bin/sed '2q;d' ${HOME}/credentials/shit`"
DB_U="`/bin/sed '3q;d' ${HOME}/credentials/shit`"

HOST=""
if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:DBaaS-secured ] )
then
    HOST="127.0.0.1"
elif ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:DBaaS ] )
then
    HOST="`/bin/ls ${HOME}/.ssh/DBaaSHOSTNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
else
    HOST="`/bin/ls ${HOME}/.ssh/MYPUBLICIP:* | /usr/bin/awk -F':' '{print $NF}'`"
fi

DB_PORT="`/bin/ls ${HOME}/.ssh/DB_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"

ips="`/bin/ls ${HOME}/config/webserverips`"

if ( [ "${ips}" = "" ] )
then
    exit
fi

for ip in ${ips}
do
    IPMASK="`/bin/echo $ip | /bin/grep -oE '[0-9]{1,3}\.[0-9]{1,3}' | /usr/bin/head -1`"
    IPMASK=${IPMASK}".%.%" 
    /usr/bin/mysql -A -u root -p${DB_P} --host="localhost" --port="${DB_PORT}" -e "CREATE USER \"${DB_U}\"@'${IPMASK}' IDENTIFIED BY '${DB_P}';"
    /usr/bin/mysql -A -u root -p${DB_P} --host="localhost" --port="${DB_PORT}" -e "GRANT ALL PRIVILEGES ON ${DB_N}.* TO \"${DB_U}\"@\"${IPMASK}\" WITH GRANT OPTION;"
done