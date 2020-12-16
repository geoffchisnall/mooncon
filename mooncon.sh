#!/usr/bin/env bash

#Inspired by nahamsec - https://github.com/nahamsec

echo "
███▄ ▄███▓ ▒█████   ▒█████   ███▄    █  ▄████▄   ▒█████   ███▄    █ 
▓██▒▀█▀ ██▒▒██▒  ██▒▒██▒  ██▒ ██ ▀█   █ ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ 
▓██    ▓██░▒██░  ██▒▒██░  ██▒▓██  ▀█ ██▒▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒
▒██    ▒██ ▒██   ██░▒██   ██░▓██▒  ▐▌██▒▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒
▒██▒   ░██▒░ ████▓▒░░ ████▓▒░▒██░   ▓██░▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░
░ ▒░   ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒ 
░  ░      ░  ░ ▒ ▒░   ░ ▒ ▒░ ░ ░░   ░ ▒░  ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░
░      ░   ░ ░ ░ ▒  ░ ░ ░ ▒     ░   ░ ░ ░        ░ ░ ░ ▒     ░   ░ ░ 
       ░       ░ ░      ░ ░           ░ ░ ░          ░ ░           ░ 
                                        ░                           
"

todate=$(date "+%Y-%m-%d")
foldername=recon-$todate
directory=recon
domain=$1

#Check if jq, sublist3r, httprobe is installed

if [ ! -x "$(command -v jq)" ]; then
	echo "[-] This script requires jq. Exiting."
	exit 1
fi

if [ ! -x "$(command -v sublist3r )" ]; then
	echo "[-] This script requires sublist3r. Exiting."
	exit 1
fi

if [ ! -x "$(command -v httprobe)" ]; then
	echo "[-] This script requires httprobe. Exiting."
	exit 1
fi

usage() { echo -e "Usage: ./mooncon.sh domain.com" 1>&2; exit 1; }

if [ -z "${domain}" ]; then
   usage; exit 1;
fi

echo "Starting recon phase"
echo ""

if [ -d "$directory" ]
then 
	echo "Directory for target $directory already exists"

else
	echo "Creating directory for target $directory."
	mkdir $directory
fi


if [ -d "$directory/$domain" ]
then 
	echo "Directory for target $directory/$domain already exists"

else
	echo "Creating directory for target $directory/$domain."
	mkdir $directory/$domain
fi

if [ -d "$directory/$domain/$foldername" ]
then
  echo "Directory for $directory/$domain/$foldername already exists"

else
  echo "Creating directory for $directory/$domain/$foldername."
  mkdir $directory/$domain/$foldername
fi

cd $directory/$domain

echo ""
echo ""
echo "[+] Starting Sublist3r [+]"
sublist3r -d $domain -o $foldername/$domain.txt > /dev/null 2>&1
sed 's/<BR>/\n/g' $foldername/$domain.txt | tee $foldername/$domain.sublist3r > /dev/null
rm $foldername/$domain.txt
echo "[+] Number of subdomains found in sublist3r: $(cat $foldername/$domain.sublist3r | wc -l)"

echo ""

echo "[+] Starting crtsh [+]"
curl -s https://crt.sh/?q=$domain\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $foldername/$domain.crtsh > /dev/null
echo "[+] Number of subdomains found in crtsh: $(cat $foldername/$domain.crtsh | wc -l)"

echo ""

echo "[+] Joining the files [+]"
echo ""
echo "[+] Adding Sublist3r [+]"
cat $foldername/$domain.sublist3r | tee $foldername/$domain.domains.tmp > /dev/null 2>&1
echo "[+] Adding crtsh [+]"
cat $foldername/$domain.crtsh | tee -a $foldername/$domain.domains.tmp > /dev/null 2>&1
cat $foldername/$domain.domains.tmp | sort -u | tee $foldername/$domain.domains > /dev/null 2>&1
rm $foldername/$domain.domains.tmp
echo "[+] Number of unique subdomains found: $(cat $foldername/$domain.domains | wc -l)"
echo "[+] Check : $directory/$domain/$foldername/$domain.domains"

echo ""

echo "[+] Let's check if the sites are up [+]"

#echo "starting httprobe"
#cat $foldername/$domain.domains | httprobe | tee $foldername/$domain.up > /dev/null 2>&1
#cat $foldername/$domain.domains | httprobe | tee $foldername/$domain.up 
#echo "[+] Number of domains found that are responding: $(cat $foldername/$domain.up | wc -l)"
#echo "[+] Number of domains found that are https: $(cat $foldername/$domain.up | grep "https://" | wc -l)"
#echo "[+] Number of domains found that are http: $(cat $foldername/$domain.up | grep "http://" |  wc -l)"

echo ""

echo "[+] Finding the IPs of the subdomains [+]"
echo ""
while read ip;
do
	ipres=$(host $ip | awk '/has address/ {print$1, $4}' | tee -a $foldername/$domain.all.tmp)
	if [ "$ipres" != '' ];
		then
			echo "$ipres" > /dev/null 2>&1
	fi
done < $foldername/$domain.domains

echo "[+] Let's group the subdomains and ips together [+]"
echo ""
#Sort the Domains with IPs
cat $foldername/$domain.all.tmp | sort -u | tee $foldername/$domain.all > /dev/null 2>&1
echo "[+] Number of subdomains with ips found: $(cat $foldername/$domain.all | wc -l)"
echo "[+] Check : $directory/$domain/$foldername/$domain.all"
echo ""
#Sort the IPs
cat $foldername/$domain.all.tmp | awk '{print $2}' | sort -u | tee $foldername/$domain.ips > /dev/null 2>&1
echo "[+] Number of IPs found: $(cat $foldername/$domain.ips | wc -l)"
echo "[+] Check : $directory/$domain/$foldername/$domain.ips"
rm $foldername/$domain.all.tmp

echo ""


echo "Let's get the geolocation of the subdomains and IPs"
while read domainfile;
do
	domainname=$(echo $domainfile | awk '{print $1}')
	domainip=$(echo $domainfile | awk '{print $2}')
	domainisp=$(curl -s http://ipwhois.app/json/$domainip | jq '"\(.continent), \(.country), \(.org)"' )
	echo $domainname, $domainip, $domainisp | tee -a $foldername/$domain.geolocation
done < $foldername/$domain.all
echo ""
echo "[+] Check : $directory/$domain/$foldername/$domain.geolocation"
echo ""
echo "[+] DONE [+]"