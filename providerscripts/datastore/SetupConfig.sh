#!/bin/sh
###################################################################################
# Description: Setup the shared config directory
# Date: 18/11/2016
# Author : Peter Winter
###################################################################################
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
####################################################################################
####################################################################################
#set -x

if ( [ "`/bin/ls ${HOME}/config 2>&1 | /bin/grep "Transport endpoint is not connected"`" != "" ] )
then
    /bin/umount -f ${HOME}/config
fi

if ( [ "`/bin/mount | /bin/grep ${HOME}/config`" != "" ] )
then
    exit
fi

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
DATASTORE_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DATASTORECHOICE'`"
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"

configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"
endpoint="`/bin/grep host_base ~/.s3cfg | /usr/bin/awk '{print $NF}'`"

if ( [ "${DATASTORE_CHOICE}" = "amazonS3" ] )
then
    export AWSACCESSKEYID=`/bin/grep 'access_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/grep 'secret_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    
    if ( [ "`/bin/mount | /bin/grep ${HOME}/config`" = "" ] )
    then
       if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ENABLEEFS:1`" = "1" ] )
       then
           aws_region="`/bin/grep region ${HOME}/.aws/config | /usr/bin/awk '{print $NF}'`"
           /bin/mkdir ~/.aws 2>/dev/null
           /bin/cp ${HOME}/.aws/* ~/.aws 2>/dev/null

           /usr/bin/aws efs describe-file-systems | /usr/bin/jq '.FileSystems[] | .CreationToken + " " + .FileSystemId' | /bin/sed 's/\"//g' | while read identifier
           do
                if ( [ "`/bin/echo ${identifier} | /bin/grep ${configbucket}`" != "" ] )
                then
                    id="`/bin/echo ${identifier} | /usr/bin/awk '{print $NF}'`"
                    efsmounttarget="`/usr/bin/aws efs describe-mount-targets --file-system-id ${id} | /usr/bin/jq '.MountTargets[].IpAddress' | /bin/sed 's/"//g'`"
                    /bin/mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsmounttarget}:/   ${HOME}/config
                 fi
            done
        else
            /usr/bin/s3cmd mb s3://${configbucket}
            /usr/bin/s3fs -o nonempty,allow_other,kernel_cache,use_path_request_style,sigv2 -ourl=https://${endpoint} ${configbucket} ${HOME}/config
        fi
    fi
fi

if ( [ "${DATASTORE_CHOICE}" = "digitalocean" ] )
then
    export AWSACCESSKEYID=`/bin/grep 'access_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/grep 'secret_key' ~/.s3cfg  | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty,allow_other,kernel_cache,use_path_request_style,sigv2 -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_CHOICE}" = "exoscale" ] )
then
    export AWSACCESSKEYID=`/bin/grep 'access_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/grep 'secret_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty,allow_other,kernel_cache,use_path_request_style,sigv2 -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_CHOICE}" = "linode" ] )
then
    export AWSACCESSKEYID=`/bin/grep 'access_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/grep 'secret_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty,allow_other,kernel_cache,use_path_request_style -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_CHOICE}" = "vultr" ] )
then
    export AWSACCESSKEYID=`/bin/grep 'access_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/grep 'secret_key' ~/.s3cfg | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty,allow_other,kernel_cache,use_path_request_style,sigv2 -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi


if ( [ ! -d ${HOME}/config/beingbuiltips ] )
then
    /bin/mkdir -p ${HOME}/config/beingbuiltips
    /bin/chmod 700 ${HOME}/config/beingbuiltips
fi
if ( [ ! -d ${HOME}/config/webserverpublicips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverpublicips
    /bin/chmod 700 ${HOME}/config/webserverpublicips
fi
if ( [ ! -d ${HOME}/config/webserverips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverips
    /bin/chmod 700 ${HOME}/config/webserverips
fi

if ( [ ! -d ${HOME}/config/databaseip ] )
then
    /bin/mkdir -p ${HOME}/config/databaseip
    /bin/chmod 700 ${HOME}/config/databaseip
fi
if ( [ ! -d ${HOME}/config/databasepublicip ] )
then
    /bin/mkdir -p ${HOME}/config/databasepublicip
    /bin/chmod 700 ${HOME}/config/databasepublicip
fi
if ( [ ! -d ${HOME}/config/bootedwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/bootedwebserverips
    /bin/chmod 700 ${HOME}/config/bootedwebserverips
fi
if ( [ ! -d ${HOME}/config/shuttingdownwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/shuttingdownwebserverips
    /bin/chmod 700 ${HOME}/config/shuttingdownwebserverips
fi
if ( [ ! -d ${HOME}/config/autoscalerip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerip
    /bin/chmod 700 ${HOME}/config/autoscalerip
fi
if ( [ ! -d ${HOME}/config/autoscalerpublicip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerpublicip
    /bin/chmod 700 ${HOME}/config/autoscalerpublicip
fi
if ( [ ! -d ${HOME}/config/buildclientip ] )
then
    /bin/mkdir -p ${HOME}/config/buildclientip
    /bin/chmod 700 ${HOME}/config/buildclientip
fi
if ( [ ! -d ${HOME}/config/credentials ] )
then
    /bin/mkdir -p ${HOME}/config/credentials
    /bin/chmod 700 ${HOME}/config/credentials
fi
if ( [ ! -d ${HOME}/config/cpuaggregator ] )
then
    /bin/mkdir -p ${HOME}/config/cpuaggregator
    /bin/chmod 700 ${HOME}/config/cpuaggregator
fi

if ( [ ! -d ${HOME}/config/webrootsynctunnel ] )
then
    /bin/mkdir -p ${HOME}/config/webrootsynctunnel
    /bin/chmod 700 ${HOME}/config/webrootsynctunnel
fi

if ( [ ! -d ${HOME}/config/ssl ] )
then
    /bin/mkdir -p ${HOME}/config/ssl
    /bin/chmod 700 ${HOME}/config/ssl
fi
