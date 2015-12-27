#!/bin/bash
# Date : 2015年10月26日16:22:32
# Author : houqian
# Contact : houqian@oneapm.com
# Company : www.110monitor.com
# OneAlert pre install script : nagios
set -e
logfile="onealert-agent-install.log"
SYSTEM_TIME=`date '+%Y-%m-%d %T'`
NAGIOS_APPKEY=97fc539f-16c4-40e3-c1d7-dd6f6c947ac2
# color
yellow='\e[0;33m'
green='\e[0;32m' 
endColor='\e[0m'

YUM_URL="http://192.168.1.13:80"
INSTALL_PROCESS_URL="http://192.168.1.1:8080/alert/api/escalation/agentInstall/$NAGIOS_APPKEY"
MENU_CEP_URL="http://192.168.1.1:8080/alert/api/event"
HB_URL="http://192.168.1.1:8080/alert/api/heartbeat/"

# detect whether the current user is root.
# Root user detection
if [ $(echo "$UID") = "0" ]; then
    sudo_cmd=''
else
    sudo_cmd='sudo'
fi

OS=RedHat
#update status
curl -d "status=creating" $INSTALL_PROCESS_URL
echo -e "\n"
if [ -n "$NAGIOS_APPKEY" ]; then
    app_key=$NAGIOS_APPKEY
else
    echo -e "${yellow} $SYSTEM_TIME - Missing NAGIOS_APPKEY end of the install command.${endColor}" >> $logfile
    exit 3;
fi

# depending on the operating system version installed agent.
if [ $OS = "RedHat" ]; then
    echo -e "\033[34m\n* Installing YUM sources for OneAlert\n\033[0m"
    $sudo_cmd rm -fr /etc/yum.repos.d/onealert-agent.repo
    $sudo_cmd sh -c "echo -e '[onealert-agent]\nname=OneAlert, Inc.\nbaseurl=$YUM_URL/centos6/x86_64/\nenabled=1\ngpgcheck=0\npriority=1\n' > /etc/yum.repos.d/onealert-agent.repo"

    echo -e "\033[34m* Installing the OneAlert Agent package\n\033[0m\n"
    #update status
    curl -d "status=pedding" $INSTALL_PROCESS_URL
    $sudo_cmd yum -y --disablerepo='*' --enablerepo='onealert-agent' install onealert-nagios-agent
    #update status
    curl -d "status=installed" $INSTALL_PROCESS_URL
    echo -e "\n"
fi

echo -e "${green}Yum install OneAlert Agent Successful!${endColor}"
echo -e "\n"

echo -e "Start to set configuration..."
# Set the configuration
$sudo_cmd chmod -R +x /usr/local/nagios/libexec/alert-agent
$sudo_cmd chmod -R +x /usr/local/nagios/libexec/nagios
if [ -e /usr/local/nagios/etc/objects/110monitor.cfg ]; then
    echo -e "\033[34m\n* Adding your license key to the Agent configuration: /usr/local/nagios/etc/objects/110monitor.cfg\n\033[0m\n"
    $sudo_cmd cp /usr/local/nagios/etc/objects/110monitor.cfg /usr/local/nagios/etc/objects/110monitor.cfg.example
    $sudo_cmd sed -i "s%your_app_key%$NAGIOS_APPKEY%g" /usr/local/nagios/etc/objects/110monitor.cfg.example
    $sudo_cmd sed -i "s%your_app_key%$NAGIOS_APPKEY%g" /usr/local/nagios/etc/objects/110monitor.cfg
    $sudo_cmd sed -i "s%your_app_key%$NAGIOS_APPKEY%g" /usr/local/nagios/libexec/alert-agent/conf/runtime.properties
    $sudo_cmd sed -i "s%alert_url%$MENU_CEP_URL%g" /usr/local/nagios/libexec/alert-agent/conf/runtime.properties
    $sudo_cmd sed -i "s%hb_url%$HB_URL%g" /usr/local/nagios/libexec/alert-agent/conf/runtime.properties
fi

# Reference 110monitor.cfg in the nagios.cfg
$sudo_cmd sh -c "echo 'cfg_file=/usr/local/nagios/etc/objects/110monitor.cfg' >> /usr/local/nagios/etc/nagios.cfg"
echo -e "End to set configuration..."

# Start heartbeat daemon
$sudo_cmd chmod +x /usr/local/nagios/libexec/alert-agent/bin/heartbeat-daemon.sh
$sudo_cmd sh /usr/local/nagios/libexec/alert-agent/bin/heartbeat-daemon.sh start
#update status
echo -e "\n"
curl -d "status=success" $INSTALL_PROCESS_URL
echo -e "${green}\nCongratulations!\n :P${endColor}"
