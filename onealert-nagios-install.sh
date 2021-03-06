#!/bin/bash
# Date : 2015年10月26日16:22:32
# Author : houqian
# Contact : houqian1991@foxmail.com
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

# OS/Distro Detection
# Try lsb_release, fallback with /etc/issue then uname command
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|Amazon)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || uname -s)
if [ $DISTRIBUTION = "Darwin" ]; then
    echo -e "${yellow} $SYSTEM_TIME - This script does not support installing on the Mac..${endColor}\n"
	echo -e "${yellow} This script does not support installing on the Mac..${endColor}\n" >> $logfile
    exit 1;
elif [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" ]; then
	echo -e "${yellow} This script does not support installing on the $DISTRIBUTION..${endColor}\n"
	echo -e "${yellow} This script does not support installing on the $DISTRIBUTION..${endColor}\n" >> $logfile
    #OS="Debian"
	exit 1;
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" -o "$DISTRIBUTION" == "Amazon" ]; then
    OS="RedHat"
	echo -e " $SYSTEM_TIME - Current OS is $OS." >> $logfile
elif [ -f /etc/system-release -o "$DISTRIBUTION" == "Amazon" ]; then
    echo -e "${yellow} $SYSTEM_TIME - This script does not support installing on the $DISTRIBUTION..${endColor}\n"
	#OS="RedHat"
	exit 1;
fi

# detecting alert agent is already intalled.
#nagiosAgentPath="/usr/local/nagios/libexec/alert-agent"
#if [ ! -e "$nagiosAgentPath"]; then
#　　echo -e "${yellow} $SYSTEM_TIME - OneAlert agent maybe installed,Please uninstall first.\n You can run 'yum uninstall onealert-agent -y' to remove it.${endColor}"
#	echo -e "${yellow} $SYSTEM_TIME - OneAlert agent path already exist.Please uninstall it first.${endColor}" >> $logfile
#	exit 0
#fi

# detection the Nagios of installation
check_yum_na='rpm -q nagios'


# detect whether the current user is root.
# Root user detection
if [ $(echo "$UID") = "0" ]; then
    sudo_cmd=''
else
    sudo_cmd='sudo'
fi

if [ -n "$NAGIOS_APPKEY" ]; then
    app_key=$NAGIOS_APPKEY
fi

# depending on the operating system version installed agent.
if [ $OS = "RedHat" ]; then
    echo -e "\033[34m\n* Installing YUM sources for OneAlert\n\033[0m"

    $sudo_cmd sh -c "echo -e '[onealert-agent]\nname=OneAlert, Inc.\nbaseurl=$YUM_URL/centos6/x86_64/\nenabled=1\ngpgcheck=0\npriority=1\n' > /etc/yum.repos.d/onealert-agent.repo"

    echo -e "\033[34m* Installing the OneAlert Agent package\n\033[0m\n"
	
    $sudo_cmd yum -y --disablerepo='*' --enablerepo='onealert-agent' install onealert-agent
fi

echo -e "${green}Yum install OneAlert Agent Succeful!${endColor}"

echo -e "Start to set configuration..."
# Set the configuration
if [ -e /usr/local/nagios/etc/objects/110monitor.cfg ]; then
    echo -e "\033[34m\n* Adding your license key to the Agent configuration: /usr/local/nagios/etc/objects/110monitor.cfg\n\033[0m\n"
	$sudo_cmd cp /usr/local/nagios/etc/objects/110monitor.cfg /usr/local/nagios/etc/objects/110monitor.cfg.example
    $sudo_cmd sh -c "sed -i 's/your-app-key:.*/your-app-key: $NAGIOS_APPKEY/' /usr/local/nagios/etc/objects/110monitor.cfg.example > /usr/local/nagios/etc/objects/110monitor.cfg"
fi

<<<<<<< HEAD:onealert-nagios-install.sh
# Reference 110monitor.cfg in the nagios.cfg
110monitor_concat=`cat /usr/local/nagios/etc/nagios.cfg | grep cfg_file=/usr/local/nagios/etc/objects/110monitor.cfg`
if [! -n "$110monitor_concat" ]; then
	$sudo_cmd sh -c "echo 'cfg_file=/usr/local/nagios/etc/objects/110monitor.cfg' >> /usr/local/nagios/etc/nagios.cfg"
fi
echo -e "End to set configuration..."
print "${green}Congratulations!${endColor}"
=======
echo -e "${green}Congratulations!${endColor}"
>>>>>>> 6c8a2a5abea9d9dead33a841af8b1d0ff10efac0:onealert.sh
