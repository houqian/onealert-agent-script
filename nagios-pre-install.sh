#!/bin/bash
# Date : 2015年10月26日16:22:32
# Author : houqian
# Contact : houqian@oneapm.com
# Company : www.110monitor.com
# OneAlert pre install script : nagios
set -e
logfile="onealert-agent-install.log"
SYSTEM_TIME=`date '+%Y-%m-%d %T'`

# color
yellow='\e[0;33m'
green='\e[0;32m' 
endColor='\e[0m'

YUM_URL=http://m.test.110monitor.com:8082
INSTALL_PROCESS_URL=http:192.168.1.1:8080/alert/api/


# detect whether the current user is root.
# Root user detection
if [ $(echo "$UID") = "0" ]; then
    sudo_cmd=''
else
    sudo_cmd='sudo'
fi

#detection the OS Ver.
IS_REDHAT=$sudo_cmd cat /etc/issue | grep "Red Hat"
IS_CENTOS=$sudo_cmd cat /etc/issue | grep "CentOS"
IS_UBUNTU=$sudo_cmd cat /etc/issue | grep "Ubuntu"

#update status
curl -d "status=creating" $INSTALL_PROCESS_URL

if [ -n $IS_CENTOS ]; then
    OS="RedHat"
    echo -e " $SYSTEM_TIME - Current OS is $OS." >> $logfile
elif [ -n $IS_REDHAT ]; then
    OS="RedHat"
    echo -e " $SYSTEM_TIME - Current OS is $OS." >> $logfile
elif [ -n $IS_UBUNTU  ]; then
    echo -e "${yellow} $SYSTEM_TIME - This script does not support installing on the $IS_UBUNTU..${endColor}\n" >> $logfile
    exit 1;
else
    echo -e "${yellow} $SYSTEM_TIME - This script does not support installing on your OS.${endColor}\n" >> $logfile
    exit 1;
fi

# detection the Nagios of installation
check_yum_na='rpm -q nagios'



if [ -n "$NAGIOS_APPKEY" ]; then
    app_key=$NAGIOS_APPKEY
else
    echo -e "${yellow} $SYSTEM_TIME - Missing NAGIOS_APPKEY end of the install commadn.${endColor}\n" >> $logfile
    exit 3;
fi

# depending on the operating system version installed agent.
if [ $OS = "RedHat" ]; then
    echo -e "\033[34m\n* Installing YUM sources for OneAlert\n\033[0m"

    $sudo_cmd sh -c "echo -e '[onealert-agent]\nname=OneAlert, Inc.\nbaseurl=$YUM_URL/centos6/x86_64/\nenabled=1\ngpgcheck=0\npriority=1\n' > /etc/yum.repos.d/onealert-agent.repo"

    echo -e "\033[34m* Installing the OneAlert Agent package\n\033[0m\n"
    #update status
    curl -d "status=pedding" $INSTALL_PROCESS_URL
    $sudo_cmd yum -y --disablerepo='*' --enablerepo='onealert-agent' install onealert-agent
    #update status
    curl -d "status=installed" $INSTALL_PROCESS_URL
fi

echo -e "${green}Yum install OneAlert Agent Succeful!${endColor}"

echo -e "Start to set configuration..."
# Set the configuration
if [ -e /usr/local/nagios/etc/objects/110monitor.cfg ]; then
    echo -e "\033[34m\n* Adding your license key to the Agent configuration: /usr/local/nagios/etc/objects/110monitor.cfg\n\033[0m\n"
    $sudo_cmd cp /usr/local/nagios/etc/objects/110monitor.cfg /usr/local/nagios/etc/objects/110monitor.cfg.example
    $sudo_cmd sh -c "sed -i 's/your-app-key:.*/your-app-key: $NAGIOS_APPKEY/' /usr/local/nagios/etc/objects/110monitor.cfg.example > /usr/local/nagios/etc/objects/110monitor.cfg"
fi

# Reference 110monitor.cfg in the nagios.cfg
110monitor_concat=`cat /usr/local/nagios/etc/nagios.cfg | grep cfg_file=/usr/local/nagios/etc/objects/110monitor.cfg`
if [! -n "$110monitor_concat" ]; then
    $sudo_cmd sh -c "echo 'cfg_file=/usr/local/nagios/etc/objects/110monitor.cfg' >> /usr/local/nagios/etc/nagios.cfg"
fi
echo -e "End to set configuration..."

# Start heartbeat daemon
$sudo_cmd sh /usr/local/nagios/libexec/alert-agent/heartbeat-daemon.sh start
#update status
curl -d "status=success" $INSTALL_PROCESS_URL
print "${green}Congratulations!\n :P${endColor}"
