#!/bin/bash
modules_dat="/opt/rusiem/modules_user.dat"

echo "Install RvSIEM free (kernel + database)"

function run_preinst  {
	apt-get install apt-transport-https software-properties-common -y
	echo -n | openssl s_client -connect support.rusiem.com:443 | \
	sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | \
	sudo tee '/usr/local/share/ca-certificates/support.rusiem.com.crt'
	update-ca-certificates
	echo -n | openssl s_client -connect orion.rusiem.com:443 | \
	sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | \
	sudo tee '/usr/local/share/ca-certificates/orion.rusiem.com.crt'
	update-ca-certificates
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3E05DF0A
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys DC47E1DD
	sed -i '/support.rusiem.com/d' /etc/apt/sources.list
	sed -i '/orion.rusiem.com/d' /etc/apt/sources.list
	if [ "$(dpkg --list | grep dmidecode | awk '{print $3}')" != "3.2-1" ]; then
		cd /tmp
		#wget http://mirrors.kernel.org/ubuntu/pool/main/d/dmidecode/dmidecode_3.2-1_amd64.deb
		wget http://mirrors.edge.kernel.org/ubuntu/pool/main/d/dmidecode/dmidecode_3.2-1_amd64.deb
		if [ -f "dmidecode_3.2-1_amd64.deb" ]; then dpkg -i dmidecode_3.2-1_amd64.deb;else "$(tput setaf 1)Package dmidecode_3.2-1_amd64.deb not found$(tput sgr 0)";fi
	fi
	tk=$(/usr/sbin/dmidecode -s system-uuid | awk '{print toupper($0)}')
	add-apt-repository "deb https://support.rusiem.com/pubrepo/debian trusty main"
	add-apt-repository "deb https://orion.rusiem.com/pubrepo/debian trusty main"
	add-apt-repository "deb https://$tk@support.rusiem.com/repo/debian trusty main"
	add-apt-repository "deb https://$tk@orion.rusiem.com/repo/debian trusty main"
}

run_preinst
apt-get remove postgres*
apt-get update
apt-get install rusiem-web rusiem-database rvsiem-kernel rusiem-kb -y
cp /opt/rusiem/modules.dat $modules_dat
cat /dev/null > $modules_dat
echo "siem=0" >> $modules_dat
echo "analytics=0" >> $modules_dat
echo "free_rvsiem=1" >> $modules_dat
echo "update_method=\"deb\"" >> $modules_dat
echo "whitelabel=0" >> $modules_dat
echo "web=1" >> $modules_dat
echo "lm=1" >> $modules_dat
echo "data_node=1" >> $modules_dat
echo "data_host=\"127.0.0.1\"" >> $modules_dat
echo "data_port=\"9200\"" >> $modules_dat
echo "system_syslog=1" >> $modules_dat
echo "allow_update=1" >> $modules_dat
echo "os_update=1" >> $modules_dat
echo "binary_update=1" >> $modules_dat
echo "kb_update=1" >> $modules_dat
echo "fw_update=0" >> $modules_dat
echo "web_update=1" >> $modules_dat
echo "kernel_update=1" >> $modules_dat
echo "arp_scan=1" >> $modules_dat
echo "auto_clean=1" >> $modules_dat
echo "rkn_monitor=1" >> $modules_dat
echo "nmap_scan=1" >> $modules_dat


sh /opt/rusiem/support/java_upto8.sh
/opt/rusiem/update/bin/update-hourly.sh
apt-get install --reinstall rusiem-web -y
/opt/rusiem/update/bin/update-kb.sh


