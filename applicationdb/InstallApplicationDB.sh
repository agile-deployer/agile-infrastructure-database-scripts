#!/bin/sh
#################################################################################################################
# Author: Peter Winter
# Date  : 10/4/2016
# Description : This scripts will actually install the application into your database. It expects some sort of
# mysql database to be online for it to install the application code into
#################################################################################################################
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

exec >>${HOME}/logs/DATABASESERVER_APPLICATION_INSTALLATION_BUILD.log
exec 2>&1
if ( [ "${HOME}" = "" ] )
then
    export HOME="`/bin/ls -ld /home/X*X | /usr/bin/awk '{print $NF}'`"
fi

if ( [ "${1}" = "force" ] )
then
    if ( [ -f ${HOME}/.ssh/BUILDARCHIVECHOICE:baseline ] )
    then
        exit
    fi
    /bin/rm ${HOME}/config/APPLICATION_INSTALLED
    /bin/rm ${HOME}/runtime/APPLICATION_INSTALLED
fi

if ( [ -f ${HOME}/config/APPLICATION_INSTALLED ] || [ -f ${HOME}/runtime/APPLICATION_INSTALLED ] || [ ! -f ${HOME}/runtime/DB_INITIALISED ] )
then
    exit
fi

if ( [ "${DB_N}" = "" ] && [ "${DB_P}" = "" ] && [ "${DB_U}" = "" ] )
then
    DB_N="`/bin/sed '1q;d' ${HOME}/credentials/shit`"
    DB_P="`/bin/sed '2q;d' ${HOME}/credentials/shit`"
    DB_U="`/bin/sed '3q;d' ${HOME}/credentials/shit`"
fi

DATASTORE_PROVIDER="`/bin/ls ${HOME}/.ssh/DATASTORECHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
ROOT_DOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/cut -d'.' -f2-`"
SUB_DOMAIN="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/awk -F'.' '{print $1}'`"
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"
WEBSITE_SUBDOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"
WEBSITE_DISPLAY_NAME="`/bin/ls ${HOME}/.ssh/WEBSITEDISPLAYNAME:* | /usr/bin/awk -F':' '{print $NF}' | /bin/sed 's/_/ /g'`"
WEBSITE_DISPLAY_NAME_UPPER="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
WEBSITE_DISPLAY_NAME_LOWER="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
APPLICATION_REPOSITORY_PROVIDER="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYPROVIDER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_OWNER="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYOWNER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_USERNAME="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_PASSWORD="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
BASELINE_DB_REPOSITORY_NAME="`/bin/ls ${HOME}/.ssh/BASELINEDBREPOSITORY:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ "${BUILD_ARCHIVE_CHOICE}" = "" ] )
then
    BUILD_ARCHIVE_CHOICE="`/bin/ls ${HOME}/.ssh/BUILDARCHIVECHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
fi
if ( [ "${BUILD_IDENTFIER}" = "" ] )
then
    BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
fi

/bin/echo "${0} `/bin/date`: Installing Application Database" >> ${HOME}/logs/MonitoringLog.dat

count=0
while ( ( [ "`/bin/ls /installer/${BUILD_ARCHIVE_CHOICE}/* | /usr/bin/wc -l`" -lt "1" ] && [ ! -f /installer/${WEBSITE_NAME}-DB-full.tar.gz ] ) && [ "${count}" != "5" ] )
do
    if ( [ ! -d /installer ] )
    then
        /bin/mkdir /installer
    fi

    /bin/rm -r /installer/.git
    /bin/rm -r /installer/*
    cd /installer
    /usr/bin/git init

    if ( [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
    then
        ${HOME}/providerscripts/git/GitPull.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_OWNER} ${BASELINE_DB_REPOSITORY_NAME}

        /bin/cat /installer/${BUILD_ARCHIVE_CHOICE}/application-db-?? > /installer/${BUILD_ARCHIVE_CHOICE}/application-db
        /bin/rm /installer/${BUILD_ARCHIVE_CHOICE}/application-db-*
        /bin/mv /installer/${BUILD_ARCHIVE_CHOICE}/application-db /installer/${BUILD_ARCHIVE_CHOICE}/application-db-00

        if ( [ ! -f /installer/${BUILD_ARCHIVE_CHOICE}/application-db* ] )
        then
            ${HOME}/providerscripts/datastore/GetFromDatastore.sh "${DATASTORE_PROVIDER}" "`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-db-${BUILD_ARCHIVE_CHOICE}" "${WEBSITE_NAME}-DB-backup.tar.gz"
            /bin/mv /installer/${WEBSITE_NAME}-DB-backup.tar.gz ${WEBSITE_NAME}-DB-full.tar.gz
        fi
    else
        if ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
        then
            DB_REPOSITORY_NAME="${WEBSITE_NAME}-db-${BUILD_ARCHIVE_CHOICE}-${BUILD_IDENTIFIER}"
            ${HOME}/providerscripts/git/GitPull.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_OWNER} ${WEBSITE_SUBDOMAIN}-${DB_REPOSITORY_NAME}

            /bin/cat /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db-?? > /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db
            /bin/rm /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db-*
            /bin/mv /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db-00

            if ( [ -f ${HOME}/.ssh/SUPERSAFEDB:1 ] && [ ! -f /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db* ] )
            then
                ${HOME}/providerscripts/datastore/GetFromDatastore.sh "${DATASTORE_PROVIDER}" "`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-db-${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-DB-backup.tar.gz"
                /bin/mv /installer/${WEBSITE_NAME}-DB-backup.tar.gz ${WEBSITE_NAME}-DB-full.tar.gz
            fi
        fi
    fi
    count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" = "5" ] && [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
    /bin/echo "FAILED TO RETRIEVE DB SOURCE FROM REPOSITORY" >> ${HOME}/logs/MonitoringLog.dat
    /bin/echo "FAILED TO RETRIEVE DB SOURCE FROM REPOSITORY"
    exit
fi

/bin/mkdir -p ${HOME}/backups/installDB/

if ( [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
    if ( [ -f /installer/${BUILD_ARCHIVE_CHOICE}/application-db* ] )
    then
        /bin/cat /installer/${BUILD_ARCHIVE_CHOICE}/application-db* > /installer/${WEBSITE_NAME}-DB-full.tar.gz
    fi

    if ( [ "`/bin/ls /installer/${WEBSITE_NAME}-DB-full.tar.gz | /usr/bin/wc -l`" = "1" ] )
    then
        /bin/tar xvfz /installer/${WEBSITE_NAME}-DB-full.tar.gz
        /bin/mv /installer/${WEBSITE_NAME}-DB-full.tar.gz  ${HOME}/backups/installDB/latestDB.tar.gz
    fi
elif ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
    if ( [ -f /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db* ] )
    then
        /bin/cat /installer/${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-db* > /installer/${WEBSITE_NAME}-DB-full.tar.gz
    fi

    if ( [ "`/bin/ls /installer/${WEBSITE_NAME}-DB-full.tar.gz | /usr/bin/wc -l`" = "1" ] )
    then
        /bin/tar xvfz /installer/${WEBSITE_NAME}-DB-full.tar.gz
        /bin/mv /installer/${WEBSITE_NAME}-DB-full.tar.gz  ${HOME}/backups/installDB/latestDB.tar.gz
    fi
fi

cd ${HOME}/backups/installDB

if ( [ "`/bin/ls ${HOME}/backups/installDB/latestDB.tar.gz`" != "" ] )
then
    /bin/tar xvfz latestDB.tar.gz
    /bin/mv application* ${WEBSITE_NAME}DB.sql
elif ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
    /bin/echo "Something went wrong with obtaining the DB archive, can't run without it.....The END"
    exit
fi

cd /root
/bin/rm -r /installer/*

if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:Maria ] || [ -f ${HOME}/.ssh/DATABASEDBaaSINSTALLATIONTYPE:Maria ] )
then
    if ( [ "${1}" = "force" ] )
    then
        . ${HOME}/providerscripts/database/singledb/mariadb/AdjustAccessForSnapshot.sh
    fi
    . ${HOME}/applicationscripts/ApplyApplicationBranding.sh
    . ${HOME}/applicationdb/maria/InstallMariaDB.sh
fi

if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:Postgres ] || [ -f ${HOME}/.ssh/DATABASEDBaaSINSTALLATIONTYPE:Postgres ] )
then
    if ( [ "${1}" = "force" ] )
    then
        . ${HOME}/providerscripts/database/singledb/postgres/AdjustAccessForSnapshot.sh
    fi
    . ${HOME}/applicationscripts/ApplyApplicationBranding.sh
    . ${HOME}/applicationdb/postgres/InstallPostgresDB.sh
fi

if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:MySQL ] || [ -f ${HOME}/.ssh/DATABASEDBaaSINSTALLATIONTYPE:MySQL ] )
then
    if ( [ "${1}" = "force" ] )
    then
        . ${HOME}/providerscripts/database/singledb/mariadb/AdjustAccessForSnapshot.sh
    fi
    . ${HOME}/applicationscripts/ApplyApplicationBranding.sh
    . ${HOME}/applicationdb/mysql/InstallMySQLDB.sh
fi

