# mooncon

##### Summary
-A domain recon script which uses sublist3r, [crtsh](https://crt.sh/) and [certspotter](https://certspotter.com) to gather a list of subdomains, check which urls are active via [httprobe](github.com/tomnomnom/httprobe) and then uses [Aquatone](https://github.com/michenriksen/aquatone) to grab a screenshot of each url.

-usage: ./mooncon domain.com

--------------------

#### requirements:

#### [+]jq[+]

- apt install jq

--------------------

#### [+]Sublist3r[+]

- apt install sublist3r

- Get it from Github [sublist3r](https://github.com/aboul3la/Sublist3r.git)

--------------------

#### [+]HTTPROBE[+]

- Get it from Github [httprobe](github.com/tomnomnom/httprobe)

--------------------

#### [+]Aquatone[+]

- Install Google Chrome or Chromium browser -- Note: Google Chrome is currently giving unreliable results when running in headless mode, so it is recommended to install Chromium for the best results.
- Download the [latest release](https://github.com/michenriksen/aquatone/releases/latest) of Aquatone for your operating system. 
- Uncompress the zip file and move the aquatone binary to your desired location. You probably want to move it to a location in your $PATH for easier use.

https://github.com/michenriksen/aquatone


