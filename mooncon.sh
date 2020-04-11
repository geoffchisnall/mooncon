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
domain=$1

#Check if jq, httprobe and aquatone is installed

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

if [ ! -x "$(command -v aquatone)" ]; then
	echo "[-] This script requires aquaton. Exiting."
	exit 1
fi

if [ ! -x "$(command -v chromium)" ]; then
	echo "[-] This script requires chromium. Exiting."
	exit 1
fi


usage() { echo -e "Usage: ./mooncon.sh domain.com" 1>&2; exit 1; }

if [ -z "${domain}" ]; then
   usage; exit 1;
fi

echo "Starting recon phase"
echo ""

if [ -d "$domain" ]
then 
	echo "Directory for target $domain already exists"

else
	echo "Creating directory for target $domain."
	mkdir $domain
fi

if [ -d "$domain/$foldername" ]
then
  echo "Directory for $domain/$foldername already exists"

else
  echo "Creating directory for $domain/$foldername."
  mkdir $domain/$foldername
fi

cd $domain

echo ""
echo ""
echo "[+]Starting Sublist3r[+]"
sublist3r -d $domain -o $foldername/$domain.txt > /dev/null 2>&1
sed 's/<BR>/\n/g' $foldername/$domain.txt | tee $foldername/$domain.sublist3r > /dev/null
rm $foldername/$domain.txt
echo "[+] Number of domains found in sublist3r: $(cat $foldername/$domain.sublist3r | wc -l)"

echo ""

echo "[+]Starting crtsh[+]"
curl -s https://crt.sh/?q=$domain\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee $foldername/$domain.crtsh > /dev/null
echo "[+] Number of domains found in crtsh: $(cat $foldername/$domain.crtsh | wc -l)"

echo ""

echo "[+]Starting certspotter[+]"
curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep -w $domain\$ | tee $foldername/$domain.certspotter > /dev/null
echo "[+] Number of domains found in certspotter: $(cat $foldername/$domain.certspotter | wc -l)"

echo ""

echo "[+]Joining the files[+]"
echo ""
echo "[+]Adding Sublist3r[+]"
cat $foldername/$domain.sublist3r | tee $foldername/$domain.domains.tmp > /dev/null 2>&1
echo "[+]Adding crtsh[+]"
cat $foldername/$domain.crtsh | tee -a $foldername/$domain.domains.tmp > /dev/null 2>&1
echo "[+]Adding cerspotter[+]"
cat $foldername/$domain.certspotter | tee -a $foldername/$domain.domains.tmp > /dev/null 2>&1
cat $foldername/$domain.domains.tmp | sort -u | tee $foldername/$domain.domains > /dev/null 2>&1
rm $foldername/$domain.domains.tmp
echo "[+] Number of unique domains found: $(cat $foldername/$domain.domains | wc -l)"

echo ""

echo "Let's check if the sites are up"

echo "starting httprobe"
#cat $foldername/$domain.domains | httprobe | tee $foldername/$domain.up > /dev/null 2>&1
cat $foldername/$domain.domains | httprobe | tee $foldername/$domain.up 
echo "[+] Number of domains found that are responding: $(cat $foldername/$domain.up | wc -l)"
echo "[+] Number of domains found that are https: $(cat $foldername/$domain.up | grep "https://" | wc -l)"
echo "[+] Number of domains found that are http: $(cat $foldername/$domain.up | grep "http://" |  wc -l)"

echo ""

echo "Starting Aquatone"
cat $foldername/$domain.up | aquatone -ports 80,443,8000,8080,8443,9443 -chrome-path /usr/bin/chromium -out $foldername/aquatone-screenshots 2>&1
echo "Aquatone completed"
