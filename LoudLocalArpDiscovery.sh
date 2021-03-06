#!/bin/bash
#-Metadata----------------------------------------------------#
#  Filename: LoudLocalDiscovery.sh       (Update: 2016-07-21) #
#-Info--------------------------------------------------------#
#  LAN/WLAN loud discovery script for Kali Linux Rolling      #
#-Author(s)---------------------------------------------------#
#  Brockway - @rockiebrockway                                 #
#-Operating System--------------------------------------------#
#  Designed for: Kali Linux Rolling [x64] (VM - VMware)       #
#     Tested on: Kali Linux 2016.1 x64/x84/full/light/mini/vm #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#  Usage: ./LoudLocalDiscovery 10.1.1.0/24 | tee logfile.txt  #
#  ARP discovery - arp-scan                                   #
#-------------------------------------------------------------#


##### (Cosmetic) Colour output
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # User Input
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

STAGE=0                                                       # Where are we up to
TOTAL=$(grep '(${STAGE}/${TOTAL})' $0 | wc -l);(( TOTAL-- ))  # How many things have we got todo

#-------------------------------------------------------------#
#  Functions                                                  #
#-------------------------------------------------------------#

# Function to check if IP format is num.num.num.num / num between 0..255
function valid_ip()
{
if [ "$(ipcalc $1 | grep INVALID)" != "" ]; then
echo -e "\n${RED}Invalid IP address or range${RESET}"
return 0
fi
echo -e "\n${GREEN}Valid IP address or range${RESET}"
}

# Function to initiate arp-scan, save IP address results to file 
function arp_scan()
{
echo "Initiating arp-scan, resulting active host list in test.txt"
/usr/bin/arp-scan $1 | awk '{print $1}' > /tmp/test.txt
}

# Read input
echo -e "\n${PURPLE}Enter the IP address or range (nmap format) [ENTER]:${RESET}"
read range
#if [[ -z "$@" ]]; then
#    echo >&2 "You must supply an argument!"
#    exit 1
#fi
#range=$1

# Validate range is in proper format
valid_ip $range

# Read input, ask if intrusive tests should be performed
#read -r -p "Are we running more intrusive tests today? [y/n] " response
#response=${response,,}  #tolower
#if [[ $response =~ ^(y)$ ]]; then
#    nuke = 1
#else
#    nuke = 0
#fi


# Setup client assessment directory
echo -e "\n${PURPLE}Enter client name for Assessment directory creation [ENTER]:${RESET}"
read client
year=`date +%Y`
clientdir="/root/Assessments/$year/$client"
mkdir -p $clientdir
timestamp=`date +%Y_%m_%d`

# Launch arp-scan and populate active IP address list
echo -e "\n ${GREEN}[+]${RESET} Launching ${GREEN}arp-scan${RESET} on $range"
arp_scan $range
# clean up arp-scan output, redirect to client assessment directory file and timestamp the filename
sed -n  's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/&/gp' /tmp/test.txt > "${clientdir}/${timestamp}-targets.txt"
# Launch sn1per <targetfile.txt> airstrike
echo -e "\n ${GREEN}[+]${RESET} Launching ${GREEN}sniper airstrike${RESET} on $range"
/opt/sniper-git/sniper "${clientdir}/${timestamp}-targets.txt" airstrike
# move sniper data to clientdir
mv /opt/sniper-git/loot/* "$clientdir"
# eyewitness
echo -e "\n ${GREEN}[+]${RESET} Launching ${GREEN}EyeWitness${RESET} on $range"
/opt/eyewitness-git/EyeWitness.py --all-protocols -f "${clientdir}/${timestamp}-targets.txt" -d "$clientdir" --cycle All
# move eyewitness files to clientdir
mv /opt/eyewitness-git/"$client"/* "$clientdir"
