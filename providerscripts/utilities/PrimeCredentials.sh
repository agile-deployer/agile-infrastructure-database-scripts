#!/bin/sh
#####################################################################################
# Description: This script ensures that the necessary configuration is robustly in place
# for the database server to function within the framework
# Author: Peter Winter
# Date: 15/01/2017
####################################################################################
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
###################################################################################
###################################################################################
#set -x

if ( [ "`/bin/mount | /bin/grep ${HOME}/config`" != "" ] )
then
    if ( [ -f ${HOME}/credentials/shit ] && [ "`/bin/cat ${HOME}/config/credentials/shit`" = "" ] )
    then
        /bin/rm ${HOME}/config/credentials/shit
        /bin/cp ${HOME}/credentials/shit ${HOME}/config/credentials/shit
    fi
fi

if ( [ ! -f ${HOME}/.ssh/shit ] && ( [ "`/bin/mount | /bin/grep ${HOME}/config`" != "" ] && [ -f ${HOME}/config/credentials/shit ] ) )
then
    /bin/cp ${HOME}/config/credentials/shit ${HOME}/.ssh/shit
fi

if ( [ -f ${HOME}/.ssh/shit ] && ( [ "`/bin/mount | /bin/grep ${HOME}/config`" != "" ] && [ ! -f ${HOME}/config/credentials/shit ] ) )
then
    /bin/cp ${HOME}/.ssh/shit ${HOME}/config/credentials/shit
fi

${HOME}/providerscripts/utilities/UpdateIP.sh

/bin/chmod 400 ${HOME}/config/credentials/shit
/bin/chmod 400 ${HOME}/credentials/shit
/bin/chmod 400 ${HOME}/.ssh/shit

DB_N="`/bin/sed '1q;d' ${HOME}/config/credentials/shit`"
DB_P="`/bin/sed '2q;d' ${HOME}/config/credentials/shit`"
DB_U="`/bin/sed '3q;d' ${HOME}/config/credentials/shit`"

DB1_N="`/bin/sed '1q;d' ${HOME}/credentials/shit`"
DB1_P="`/bin/sed '2q;d' ${HOME}/credentials/shit`"
DB1_U="`/bin/sed '3q;d' ${HOME}/credentials/shit`"

if ( [ "${DB_N}" != "${DB1_N}" ] || [ "${DB_P}" != "${DB1_P}" ] ||  [ "${DB_U}" != "${DB1_U}" ] )
then
    /bin/cp ${HOME}/credentials/shit ${HOME}/config/credentials/shit
fi
