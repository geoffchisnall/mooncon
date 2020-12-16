#mooncon

Domain Recon

usage: ./mooncon domain.com

#v1

Grabs given domain, gets the subdomains via sublis3r, crtsh and certspotter and then runs it through httprobe to check if alive and runs it through aquatone.

#v2

- removed certspotter, httprobe and aquatone
- added nslookup to find the subdomain ips
- added geolocation

Requirements:

--------------------

[+]jq[+]

apt install jq

--------------------

[+]Sublist3r[+]

Kali Linux has it in the repository

apt install sublist3r

or install it from Github

https://github.com/aboul3la/Sublist3r.git

--------------------
