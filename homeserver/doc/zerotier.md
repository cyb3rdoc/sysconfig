## Install Zerotier on Ubuntu/Debian

Zerotier official website provides .deb package or one-line command to install ZerotierOne on Ubuntu/Debian linux systems. However, this brings 2 challenges:
1. .deb install will not automatically update package through `apt`
2. Bash command will add zerotier reporsitory but will show warning of `Missing Signed By`

Below steps addresses both these issues:

### Install Zerotier using their official and secure bash command
```
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import &amp;&amp; \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
```

### Add and configure Zerotier GPG key
```
mkdir -p -m 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/zerotier.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1657198823E52A61
chmod 644 /tmp/zerotier.gpg
sudo chown root:root /tmp/zerotier.gpg
sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/zerotier.gpg
```

### Update Zerotier sources file
```
sudo nano /etc/apt/sources.list.d/zerotier.sources
```
Add below line at the end in the file:
```
Signed-By: /usr/share/keyrings/zerotier.gpg
```
The file content should look like below:
```
Types: deb
URIs: http://download.zerotier.com/debian/noble
Suites: noble
Components: main
Signed-By: /usr/share/keyrings/zerotier.gpg
```
Save and Close the file.

### Update apt and intall Zerotier
```
sudo apt update
sudo apt install zerotier-one
```

The `Missing: Signed By` warning should be removed now.
