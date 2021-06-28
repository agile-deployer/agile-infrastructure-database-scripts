#!/bin/sh
#######################################################################################################
# Description: This script will install an application into a postgres Database
# Author: Peter Winter
# Date: 17/01/2017
#######################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################
#set -x

DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DB_PORT'`"

if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:DBaaS-secured ] )
then
    host="127.0.0.1"
elif ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:DBaaS ] )
then
    host="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSHOSTNAME'`"
else
    host=127.0.0.1
fi

if ( [ -f ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql ] )
then
    lockfile=${HOME}/config/dbinstalllock.file

    if ( [ ! -f ${lockfile} ] )
    then
        /usr/bin/touch ${lockfile}
        /bin/sed -i "s/XXXXXXXXXX/${DB_U}/g" ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql
        ipmask="`/bin/ls ${HOME}/.ssh/IPMASK:* | /usr/bin/awk -F':' '{print $NF}'`"
        /bin/sed -i "s/YYYYYYYYYY/${ipmask}/g" ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql
        olduser="`/bin/cat ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql | /bin/grep 'u........u' | /bin/sed 's/ /\n/g' | grep '^u........u$' | /usr/bin/head -1`"
        /bin/sed -i "s/${olduser}/${DB_U}/g" ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql
        export PGPASSWORD="${DB_P}"
        /usr/bin/psql -h ${host} -U ${DB_U} -p ${DB_PORT} ${DB_N} < ${HOME}/backups/installDB/${WEBSITE_NAME}DB.sql
        /bin/rm ${lockfile}
    else
        exit
    fi
fi

if ( [ "`/usr/bin/psql -h ${host} -p ${DB_PORT} -U ${DB_U} ${DB_N} -c "select exists ( select 1 from information_schema.tables where table_name='zzzz');" | /bin/grep -v 'exist' | /bin/grep -v '\-\-\-\-'  | /bin/grep -v 'row' | /bin/sed 's/ //g'`" = "t" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
then
    /bin/echo "${0} `/bin/date` : An application has been installed in the database, right on" >> ${HOME}/logs/MonitoringLog.dat
    /bin/touch ${HOME}/config/APPLICATION_INSTALLED
fi
