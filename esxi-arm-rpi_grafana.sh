#!/bin/sh
##      .SYNOPSIS
##      Bash Shell Script that uses thepimon (https://github.com/thebel1/thpimon) to extract data and save it to InfluxDB
## 
##      .DESCRIPTION
##      Bash Shell Script that uses thepimon (https://github.com/thebel1/thpimon) to extract data and save it to InfluxDB, and then visualized with Grafana 
##      The Script, and the whole thepimon it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  esxi-arm-rpi_grafana.sh
##      ORIGINAL NAME: esxi-arm-rpi_grafana.sh
##      LASTEDIT: 14/11/2020
##      VERSION: 1.1
##      KEYWORDS: VMware, ESXi, ARM
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

# Configurations
##
#thepimonPath="/thpimon-main/pyUtil/pimon_util.py"
thepimonPath="/scratch/downloads/thpimon-main/pyUtil/pimon_util.py"

##
# Variables from Python thepimon to InfluxDB
##
thepimon_output=$(python $thepimonPath)
arm_rpi_firmware=$(echo $thepimon_output | awk -F':' '{print $2}' | awk '{print $1}')
arm_rpi_boardmodel=$(echo $thepimon_output | awk -F'Model:' '{print $2}' | awk '{print $1}')
arm_rpi_boardrevision=$(echo $thepimon_output | awk -F'Board Revision:' '{print $2}' | awk '{print $1}')
arm_rpi_boardserial=$(echo $thepimon_output | awk -F'Serial:' '{print $2}' | awk '{print $1}')
arm_rpi_boardtemp=$(echo $thepimon_output | awk -F'Temp:' '{print $2}'  | awk '{print $1}')
arm_rpi_hostname=$(echo $HOSTNAME)

echo "Building the JSON file"
FILE="/usr/lib/vmware/hostd/docroot/ui/pimonarm.json"
/bin/cat <<EOM >$FILE
{
    "thpimon": {
        "title": "The simplest way to take data out of the ESXi",
        "firmware": "$arm_rpi_firmware",
        "boardmodel": "$arm_rpi_boardmodel",
        "boardrevision": "$arm_rpi_boardrevision",
        "boardserial": "$arm_rpi_boardserial",
        "boardtemp": "$arm_rpi_boardtemp",
        "hostname": "$arm_rpi_hostname"
    }
}
EOM
echo "All good, now you can go to https://$arm_rpi_hostname/ui/pimonarm.json and use the JSON on your favourite Monitoring system"
