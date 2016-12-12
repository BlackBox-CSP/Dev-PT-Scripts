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
# Launch low/slow nmap scans
echo -e "\n ${GREEN}[+]${RESET} Launching ${GREEN}nmap slow scans${RESET} on $range"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}FTP scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 19 -g 53 -Pn -n -sS --open -p21 --script=banner,ftp-anon,ftp-bounce -iL - >> "${clientdir}/`date +%Y_%m_%d`_FTP.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}SSH scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 21 -g 53 -Pn -n -sS --open -p22 --script=sshv1,ssh2-enum-algos,ssh-hostkey -iL - >> "${clientdir}/`date +%Y_%m_%d`_SSH.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}Telnet scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 23 -g 53 -Pn -n -sS --open -p23 --script=telnet-ntlm-info -iL - >> "${clientdir}/`date +%Y_%m_%d`_Telnet.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}SMTP scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 17 -g 53 -Pn -n -sS --open -p25,465,587 --script=banner,smtp-enum-users,smtp-open-relay -iL - >> "${clientdir}/`date +%Y_%m_%d`_SMTP.txt"
#echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}DNS scans${RESET} on $range"
#cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s -g 53 -Pn -n -sU --open -p53 --script=dns-cache-snoop,dns-service-discovery,dns-update,dns-zone-transfer,dns-recursion -iL - -oG "${clientdir}/`date +%Y_%m_%d`_DNS.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}NFS scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 22 -g 53 -Pn -n -sS --open -p111 --script=rpcinfo,nfs-ls,nfs-showmount,nfs-statfs -iL - >> "${clientdir}/`date +%Y_%m_%d`_NFS.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}SMB scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 24 -g 53 -Pn -n -sS --open -p139,445 --script="smb-enum*",smb-os-discovery,smb-security-mode,smb-server-stats,smb-system-info,smbv2-enabled -iL - >> "${clientdir}/`date +%Y_%m_%d`_SMB.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}LDAP scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 19 -g 53 -Pn -n -sS --open -p389 --script=ldap-rootdse -iL - >> "${clientdir}/`date +%Y_%m_%d`_LDAP.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}HTTP scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 18 -g 53 -Pn -n -sS --open -p80,443,8000,8080,8443 --script=http-date,http-enum,http-favicon,http-headers,http-open-proxy,http-php-version,http-robots.txt,http-title,http-trace,http-vhosts,citrix-enum-apps-xml,citrix-enum-servers-xml -iL - >> "${clientdir}/`date +%Y_%m_%d`_HTTP.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}SSL scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 22 -g 53 -Pn -n -sS --open -p443 --script=banner,ssl-cert,ssl-enum-ciphers,sslv2,ssl-heartbleed,ssl-poodle -iL - >> "${clientdir}/`date +%Y_%m_%d`_SSL.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}Oracle scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 17 -g 53 -Pn -n -sS --open -p1521 --script=oracle-tns-version -iL - >> "${clientdir}/`date +%Y_%m_%d`_Oracle.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}VNC scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 21 -g 53 -Pn -n -sS --open -p5800,5900 --script=vnc-info,realvnc-auth-bypass -iL - >> "${clientdir}/`date +%Y_%m_%d`_VNC.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}Java RMI scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 20 -g 53 -Pn -n -sS --open -p1099 --script=rmi-dumpregistry -iL - >> "${clientdir}/`date +%Y_%m_%d`_RMI.txt"
#echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}Citrix scans${RESET} on $range"
#cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s -g 53 -Pn -n -sU --open -p1604 --script=citrix-enum-apps,citrix-enum-servers -iL - >> "${clientdir}/`date +%Y_%m_%d`_Citrix.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}WinDX Badge System scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 20 -g 53 -Pn -n -sS --open -p10002,3001,2102,5555,5556 -iL - >> "${clientdir}/`date +%Y_%m_%d`_WinDX.txt"
echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}OnGuard Badge System scans${RESET} on $range"
cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s --data-length 23 -g 53 -Pn -n -sS --open -p8888,9999,8189 -iL - >> "${clientdir}/`date +%Y_%m_%d`_OnGuard.txt"
#echo -e " ${GREEN}[+]${RESET} Launching ${GREEN}DB2 scans${RESET} on $range"
#cat "${clientdir}/${timestamp}-targets.txt" | sort -R | /usr/bin/nmap --scan-delay 5s -g 53 -Pn -n -sS --open --version-intensity 0 -p523 --script=db2-discover,db2-das-info -iL - >> "${clientdir}/`date +%Y_%m_%d`_SSL.txt"
# eyewitness
#echo -e "\n ${GREEN}[+]${RESET} Launching ${GREEN}EyeWitness${RESET} on $range"
#/opt/eyewitness-git/EyeWitness.py --all-protocols -f "${clientdir}/${timestamp}-targets.txt" -d "$clientdir" --cycle All
# move eyewitness files to clientdir
#mv /opt/eyewitness-git/"$client"/* "$clientdir"
