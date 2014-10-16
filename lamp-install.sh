#!/usr/bin/env bash

######################################
# An interactive LAMP installer      #
# Author - Pashaxp <git@pashaxp.com> #
# 2014.                              #
######################################

### Colors for output defined here ###
#Black        0;30     Dark Gray     1;30
#Blue         0;34     Light Blue    1;34
#Green        0;32     Light Green   1;32
#Cyan         0;36     Light Cyan    1;36
#Red          0;31     Light Red     1;31
#Purple       0;35     Light Purple  1;35
#Brown/Orange 0;33     Yellow        1;33
#Light Gray   0;37     White         1;37

# Usage:
# echo -e "${Red}Hello${NC}"
# read -ep $'\E[36m'"$*"$'\E[0m'  #read keys from user until ENTER.

NC='\e[0m' # No Color
Black='\e[0;30m'
Blue='\e[0;34m'
Green='\e[0;32m'
Cyan='\e[0;36m'
Red='\e[0;31m'
Purple='\e[0;35m'
Brown='\e[0;33m'
LightGray='\e[0;37m'
DarkGray='\e[1;30m'
LightBlue='\e[1;34m'
LightGreen='\e[1;32m'
LightCyan='\e[1;36m'
LightRed='\e[1;31m'
LightPurple='\e[1;35m'
Yellow='\e[1;33m'
White='\e[1;37m'

echo ""
echo -e "${Green}  +-------------------------------------+${NC}"
echo -e "${Green}  | An interactive LAMP Installer will  |${NC}"
echo -e "${Green}  | automatically setup and configure : |${NC}"
echo -e "${Green}  | ${NC}${Yellow}Apache${Green} (with Nginx - optional)      |${NC}"
echo -e "${Green}  | ${NC}${Yellow}MySQL${Green}                               |${NC}"
echo -e "${Green}  | ${NC}${Yellow}PHP${Green} (additional modules - optional) |${NC}"
echo -e "${Green}  | ${NC}${Yellow}Other system programs${Green} (vim,mc,etc.) |${NC}"
echo -e "${Green}  +-------------------------------------+${NC}"
echo ""

### Check whether this script is launched by root ###
if [[ "$(whoami)" != 'root' ]]; then
    echo -e "${Red}Oops. You must be root to run this script.${NC}\\n"
    exit 1;
fi

### Check whether this script is launched on Debian ###
debian_true=`cat /etc/issue | grep 'Debian' | wc -l`
if [[ $debian_true -lt 1 ]]; then
    echo -e "${Red}Oops. The operating system running on this server is not Debian.${NC}\\n"
    exit 1;
fi

export DEBIAN_FRONTEND=noninteractive

### Set up logging ###
echo -en "${Cyan}"
read -p"Do you want to save the installation progress into a logfile? [Y/n] : " IsLogging
echo -en "${NC}"
if [[ "$IsLogging" != "n" ]]; then
    echo -en "${Cyan}"
    read -p "Enter a filename where to save logs [/tmp/install.log] : " LogFile
    echo -en "${NC}"
    if [[ -z "$LogFile" ]]; then
        LogFile="/tmp/install.log"
        touch $LogFile
    fi
else 
    LogFile="/dev/null"
fi

echo "" >> $LogFile 2>> $LogFile
echo "+-------------------------------------+" >> $LogFile 2>> $LogFile
echo "| An Unattended LAMP Installer will   |" >> $LogFile 2>> $LogFile
echo "| automatically setup and configure : |" >> $LogFile 2>> $LogFile
echo "| Apache (with Nginx - optional)      |" >> $LogFile 2>> $LogFile
echo "| MySQL                               |" >> $LogFile 2>> $LogFile
echo "| PHP (additional modules - optional) |" >> $LogFile 2>> $LogFile
echo "| Other system programs (vim,mc,etc.) |" >> $LogFile 2>> $LogFile
echo "+-------------------------------------+" >> $LogFile 2>> $LogFile
echo "" >> $LogFile 2>> $LogFile

### Preparing temp directory ###
echo -en "${Cyan}"
read -p "Enter Installation Directory [/tmp/lamp] : " installDir
echo -en "${NC}"
echo ""
if [[ -z "$installDir" ]]; then
    installDir="/tmp/lamp"
fi
mkdir "$installDir" >> $LogFile 2>> $LogFile
if [[ ! -d "$installDir" ]]; then
    echo -e "${Red}Could not create temp dir $installDir. Aborting.${NC}"
    exit 1;
fi

cur_dir=`pwd`
cd "$installDir"
wget -q --tries=3 --timeout=2 http://google.com > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
        sleep 0.1
else
        echo -e "${Red}This server has no Internet access. Check it, then launch installer again.${NC}"
        echo ""
        exit 1;
fi

mkpass() {
[ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32}
echo
}

progname=`basename "$0"`
cd "$cur_dir"
### Extracting files info temp directory ###

echo -en "${Purple}Extracting files into ${Red}$installDir${Purple} .${NC}"
OFFSET=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`
THISPROCESS=$0
tail -n +$OFFSET $THISPROCESS > $installDir/arch.tar.gz
cd "$installDir/."
tar xzf arch.tar.gz
if [[ $? -ne 0 ]]; then
          echo -en "${Red}Error during unpacking files. Aborting.${NC}\\n"
          exit 1;
fi
    counter=3
    while [[ $counter -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
echo -e "${Green} Done.${NC}"
echo ""

### Try-catch Ctrl+C pressing ###
cleanup()
# example cleanup function
{
    cd "$installDir"
    if [[ $? -ne 0 ]]; then
        echo -e "${Red} Temp directory ${Cyan}$installDir${Red} was not cleaned! ${NC}"

    else
        rm -rf ./*
    fi
    return $?
}
 
control_c()
# run if user hits control-c
{
  echo -e "${Green} ** Ctrl+C pressed. Cleaning temp directory ${Red}$installDir${Green} . Exiting. **${NC}"
  cleanup
  exit $?
}
 
### Trap keyboard interrupt (control-c) ###
trap control_c SIGINT

### Main loop ###
while true; 
do

### Assuming OS is Debian, then install repositories and keys ###
echo -en "${Purple}Preparing Debian repositories .${NC}"
    counter=3
    while [[ $counter -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
OSVER=`cat /etc/debian_version | awk 'BEGIN{FS="."}{print $1}'`
if [[ "$OSVER" = 6 ]]; then
    cat files/apt/sources.list_deb6 > /etc/apt/sources.list
elif [[ "$OSVER" = 7 ]]; then
	cat files/apt/sources.list_deb7 > /etc/apt/sources.list
fi
wget -q -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add - > /dev/null 2>&1
wget -q -O - http://opensource.wandisco.com/wandisco-debian.gpg | apt-key add - > /dev/null 2>&1
apt-key adv --keyserver keys.gnupg.net --recv-keys 5CB26B26 > /dev/null 2>&1
apt-get update >> $LogFile 2>> $LogFile
echo -e "${Green} Done.${NC}"
echo ""

### Installing vim, mc, rar, java, subversion, libreoffice ###
echo -en "${Purple}Installing required system components .${NC}"
    counter=3
    while [[ "$counter" -gt 0 ]]; do
    echo -en "${Purple}.${NC}"
    counter=$((counter - 1))
    sleep 1
    done
echo "apt-get -q -y install mc vim update-sun-jre subversion lftp rar zip unzip sudo atop iotop memcached sphinxsearch rsync redis-server libreoffice bash" >> $LogFile
apt-get -q -y install mc vim update-sun-jre subversion lftp rar zip unzip sudo atop iotop bash memcached sphinxsearch rsync redis-server >> $LogFile 2>> $LogFile
echo -en "${Purple} Almost finished ....${NC}"
if [[ "$OSVER" = 6 ]]; then
    echo "deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free" >> /etc/apt/sources.list
    apt-get update >> $LogFile 2>> $LogFile
    apt-get -q -y install -t squeeze-backports libreoffice >> $LogFile 2>> $LogFile
    apt-get -q -y install build-essential libcurl3 libcurl4-gnutls-dev libmagic-dev make curl gcc-4.3 make linux-headers-`uname -r`>> $LogFile 2>> $LogFile
elif [[ "$OSVER" = 7 ]]; then
    apt-get -q -y install libreoffice build-essential libcurl3 libcurl4-gnutls-dev libmagic-dev make curl gcc-4.3 make linux-headers-`uname -r` >> $LogFile 2>> $LogFile
fi

### Replacing Crontab ###
cp /etc/crontab /etc/crontab.back
cat files/etc/crontab > /etc/crontab
rm -f /etc/localtime >> $LogFile 2>> $LogFile
ln -s /usr/share/zoneinfo/Europe/Kiev /etc/localtime
wget http://source.a2o.si/download/snoopy/snoopy-1.9.0.tar.gz > /dev/null 2>&1  && tar -zxf snoopy-1.9.0.tar.gz > /dev/null 2>&1 && cd snoopy-1.9.0 && ./configure > /dev/null 2>&1 && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && make enable > /dev/null 2>&1 && echo -e '!'"snoopy \n*.* /var/log/snoopy.log" >> /etc/rsyslog.conf && /etc/init.d/rsyslog restart > /dev/null 2>&1
cd "$installDir/."
echo -e "${Green} Done.${NC}"
echo ""

### SendEmail ###
cp files/bin/sendEmail /usr/bin/
chmod +x /usr/bin/sendEmail

### Firewall ###
mkdir -p /var/lib/iptables/
cp files/bin/rules-save /var/lib/iptables/rules-save
chmod +x /var/lib/iptables/rules-save
rclocallinenumber=`grep -nr "exit" /etc/rc.local  | grep -v "#" | awk 'BEGIN{FS=":"}{print $1'}`
sed -i "${rclocallinenumber} i\\" /etc/rc.local
sed -i "${rclocallinenumber} i /var/lib/iptables/rules-save" /etc/rc.local
echo -e "${Yellow}Firewall${Green} was successfully configured.${NC}"
echo ""

### SSH ###
sed -i '/Port 22/c\Port 8822' /etc/ssh/sshd_config > /dev/null 2>&1
sed -i '/PermitRootLogin yes/c\PermitRootLogin no' /etc/ssh/sshd_config > /dev/null 2>&1
/etc/init.d/ssh restart
echo -e "${Red}** Attention! SSH login under ROOT user was disabled! **${NC}"
echo -e "${Yellow}SSH${Green} was successfully configured. New SSH port is ${Red}8822${NC}"
echo ""

### Installing AMP ###
### begin with Apache (with Nginx - optionally) ###
echo -en "${Cyan}"
read -p "Do you want to install Apache Web Server? [Y/n] : " apacheInst
echo -en "${NC}"
if [[ "$apacheInst" != "n" ]]; then
    echo -en "${Cyan}"
    read -p "Do you want to install Apache with Nginx?  [Y/n] : " apacheInstNginx
    echo -en "${NC}"
if [[ "$apacheInst" != "n" && "$apacheInstNginx" != "n" ]]; then
    echo ""
    echo -e "${Green}  +-------------------------------+${NC}"
    echo -e "${Green}  | Installing ${Yellow}Apache${Green} with ${Yellow}Nginx${Green}  |${NC}"
    echo -e "${Green}  +-------------------------------+${NC}"
    echo ""
    apt-get -q -y install apache2 apache2-doc apache2-utils >> $LogFile 2>> $LogFile
    apt-get -q -y install libapache2-mod-rpaf >> $LogFile 2>> $LogFile
    a2enmod rewrite >> $LogFile 2>> $LogFile
    /etc/init.d/apache2 stop > /dev/null 2>&1
    cp /etc/apache2/ports.conf /etc/apache2/ports.conf_back
    cp files/apache2/ports.conf /etc/apache2/ports.conf
    apt-get -q -y install nginx >> $LogFile 2>> $LogFile
    /etc/init.d/nginx stop >> $LogFile 2>> $LogFile
    cp files/nginx/proxymodule /etc/nginx/
    rm -f /etc/nginx/sites-enabled/*
    rm -f /etc/apache2/sites-enabled/*
    mkdir -p /www/projects/default
    if [[ $? -ne 0 ]]; then
          echo -e "${Red}Error during creating web-content directory. Virtualhost may not work.${NC}\\n"
    fi
    chown -R www-data. /www/projects/
    cp files/nginx/default /etc/nginx/sites-enabled/
    cp files/apache2/default-nginx /etc/apache2/sites-enabled/
    /etc/init.d/nginx start > /dev/null 2>&1
    /etc/init.d/apache2 start > /dev/null 2>&1
    nc -z -w 3 localhost 80 > /dev/null 2>&1
    if [[ $? = 0 ]]; then
    	echo -e "${Yellow}Nginx${Green} was successfully installed.${NC}"
    	nginxsuccess=1
    else echo -e "${Yellow}Nginx${Red} was installed with errors. Check it.${NC}\\n"
    fi

    nc -z -w 3 localhost 7700 > /dev/null 2>&1
    if [[ $? = 0 ]]; then
    	echo -e "${Yellow}Apache${Green} was successfully installed.${NC}"
    	apachesuccess=1
    else echo -e "${Yellow}Apache${Red} was installed with errors. Check it.${NC}\\n"
    fi
    if [[ "$nginxsuccess" = 1 && "$apachesuccess" = 1 ]]; then
	   cp files/apache2/index.html /www/projects/default/
	   ip=`ifconfig -a | grep 'inet addr' | grep -v '127.0.0.1' | awk 'BEGIN{FS=":"}{print $2}' | awk '{print $1}' | xargs | awk '{print $1}'`
	   echo -e "${Purple}You can access it now. Open ${Red}http://$ip${Purple} in your browser.${NC}\\n"
    fi

elif [[ "$apacheInst" != "n" && "$apacheInstNginx" = "n" ]]; then

### Installing Nginx ###
    echo ""
    echo -e "${Green}  +--------------------------+${NC}"
    echo -e "${Green}  |    Installing ${Yellow}Apache${Green}     |${NC}"
    echo -e "${Green}  +--------------------------+${NC}"
    echo ""
	apt-get -q -y install apache2 apache2-doc apache2-utils >> $LogFile 2>> $LogFile
	apt-get -q -y install libapache2-mod-rpaf >> $LogFile 2>> $LogFile
	mkdir -p /www/projects/default
    if [[ $? -ne 0 ]]; then
          echo -e "${Red}Error during creating web-content directory. VirtualHost may not work.${NC}"
    fi
    chown -R www-data. /www/projects/
	a2enmod rewrite >> $LogFile 2>> $LogFile
	/etc/init.d/apache2 stop > /dev/null 2>&1
	rm -f /etc/apache2/sites-enabled/*
	cp files/apache2/default /etc/apache2/sites-enabled/
	/etc/init.d/apache2 start > /dev/null 2>&1
	nc -z -w 3 localhost 80 > /dev/null 2>&1
    if [[ $? = 0 ]]; then
    	echo -e "${Yellow}Apache${Green} was successfully installed.${NC}"
    	apachesuccess=1
    else echo -e "${Yellow}Apache${Red} was installed wiht errors. Check it.${NC}\\n"
    fi
    if [[ "$apachesuccess" = 1 ]]; then
    	cp files/apache2/index.html /www/projects/default/
    	ip=`ifconfig -a | grep 'inet addr' | grep -v '127.0.0.1' | awk 'BEGIN{FS=":"}{print $2}' | awk '{print $1}' | xargs | awk '{print $1}'`
    	echo -e "${Purple}You can access it now. Open ${Red}http://$ip${Purple} in your browser.${NC}\\n"
	fi
fi
else 
    echo ""
fi

### MySQL installation ###
echo -en "${Cyan}"
read -p "Do you want to install MySQL Server? [Y/n] : " mySQLInst
echo -en "${NC}"
if [[ "$mySQLInst" != "n" ]]; then
    echo ""
    echo -e "${Green}  +--------------------------+${NC}"
    echo -e "${Green}  |    Installing ${Yellow}MySQL${Green}      |${NC}"
    echo -e "${Green}  +--------------------------+${NC}"
    echo ""
    echo -en "${Cyan}"
    read -p "Please, enter your new MySQL root password (or it will be generated automatically) : " sqlrootPass
    echo -e "${NC}"

    if [ -z $sqlrootPass ]; then
        sqlrootPass=$(mkpass 15 0)
        export sqlrootPass
        echo -e "${Purple} ** MySQL root password will be: ${Red}$sqlrootPass${Purple} . Copy it before continuing. **${NC}\\n"
        echo -en "${Cyan}"
        read -p "Are you sure you've copied MySQL root password? [Y] : " cont
        echo -e "${Cyan}"
    fi

    echo -en "${Purple}Installing MySQL Server .${NC}"
    counter=3
    while [[ "$counter" -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
    debconf-set-selections <<< 'mysql-server mysql-server/root_password password pass'
    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password pass'
    apt-get -q -y install mysql-server mysql-client libmysqlclient-dev >> $LogFile 2>> $LogFile
    mysql -u root -p"pass" mysql -e "UPDATE user SET Password=PASSWORD('$sqlrootPass') WHERE user='root'; FLUSH PRIVILEGES;" >> $LogFile 2>> $LogFile
    if [[ $? -eq 0 ]]; then
            echo -en "${Purple} ** MySQL root password successfully updated. **${NC}"
        else
            echo -en "${Red} ** MySQL root password update FAILED! **${NC}"
    fi
    echo -e "${Green} Done.${NC}"
    echo ""
else 
    echo ""
fi

### PHP installation ###
echo -en "${Cyan}"
read -p "Do you want to install PHP? [Y/n] : " PHPInst
echo -en "${NC}"
if [[ "$PHPInst" != "n" ]]; then
    echo ""
    echo -e "${Green}  +--------------------------+${NC}"
    echo -e "${Green}  |      Installing ${Yellow}PHP${Green}      |${NC}"
    echo -e "${Green}  +--------------------------+${NC}"
    echo ""
    if [[ $OSVER = 6 ]]; then
        echo -e "${Red} ** Attention needed **${NC}"
        echo ""
        echo -e "${Green}  +--------------------------------------------+${NC}"
        echo -e "${Green}  | The operating system installed on this     |${NC}"
        echo -e "${Green}  | server is: ${Yellow}** Debian 6 **${Green}                  |${NC}"
        echo -e "${Green}  | By default PHP version is to be installed  |${NC}"
        echo -e "${Green}  | ${Yellow}PHP ** 5.3 **${Green}                              |${NC}"
        echo -e "${Green}  | In case of adding custom repositories      |${NC}"
        echo -e "${Green}  | ${Yellow}PHP ** 5.4 **${Green} could be installed.          |${NC}"
        echo -e "${Green}  +--------------------------------------------+${NC}"
        echo ""
        echo -en "${Cyan}"
        read -p "Should I proceed with adding PHP 5.4 repos? [Y/n] : " PHP54ReposAdd
        echo -en "${Cyan}"
        if [ "$PHP54ReposAdd" != "n" ]; then
            cat files/apt/sources.list_deb6-php54 >> /etc/apt/sources.list
            apt-get update >> $LogFile 2>> $LogFile
        fi
    fi
    echo -en "${Purple}Installing PHP .${NC}"
    counter=3
    while [[ "$counter" -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
    apt-get -q -y install libapache2-mod-php5 php5 php5-curl php5-dev php-pear build-essential libcurl3 libcurl4-gnutls-dev libmagic-dev php-http make libpcre3-dev >> $LogFile 2>> $LogFile
    if [[ "$mySQLInst" != "n" ]]; then
        apt-get -q -y install php5-mysql >> $LogFile 2>> $LogFile
    fi
    cp files/php5/apache2/php.ini /etc/php5/apache2/php.ini
    cp files/php5/cli/php.ini /etc/php5/cli/php.ini
    echo -e "${Green} Done.${NC}"
    echo -en "${Purple}Reloading Web Server .${NC}"
    counter=3
    while [[ "$counter" -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
    /etc/init.d/apache2 restart > /dev/null 2>&1
    echo -e "${Green} Done.${NC}"
    phpver=`php -v | grep 'PHP' -m 1 | awk 'BEGIN{FS=" "}{print $2}'`
    echo -e "${Yellow}PHP $phpver ${Green}was successfully installed.${NC}"
    if [[ "$apacheInst" != "n" ]]; then
        cp files/php5/info.php /www/projects/default/
        echo -e "${Purple}You can test it here - ${Red}http://$ip/info.php${NC}"
        echo ""
    fi

### Additionap PHP modules ###
echo -en "${Cyan}"
read -p "Do you want to install additional PHP modules? (tidy, memcache, redis, geoip) [Y/n] : " PHPAdditional
echo -en "${Cyan}"
if [[ "$PHPAdditional" != "n" ]]; then
    echo -en "${Purple}Installing additional PHP modules .${NC}"
    counter=2
    while [[ "$counter" -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
    apt-get -q -y install php5-geoip php5-memcache php5-memcached php5-tidy php5-redis php5-imagick >> $LogFile 2>> $LogFile
    wget http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz >> $LogFile 2>> $LogFile
    tar xzvf ioncube_loaders_lin_x86-64.tar.gz >> $LogFile 2>> $LogFile
    mv ioncube /usr/local/ > /dev/null 2>&1
    phpdecimal=`php -v | grep 'PHP' -m 1| awk 'BEGIN{FS="."}{print $2}'`
    if [[ "$phpdecimal" = "3" ]]; then
        echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.3.so" >> /etc/php5/cli/php.ini
        echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.3.so" >> /etc/php5/apache2/php.ini
    elif [[ "$phpdecimal" = "4" ]]; then 
        echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.4.so" >> /etc/php5/cli/php.ini
        #echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.4.so" >> /etc/php5/apache2/php.ini
    fi
    cd $installDir/files/libsphinxclient/
    echo -ne '\n' | chmod 755 *
    echo -ne '\n' | ./configure >> $LogFile 2>> $LogFile
    echo -ne '\n' | make >> $LogFile 2>> $LogFile
    echo -ne '\n' | make install >> $LogFile 2>> $LogFile
    echo -ne '\n' | pecl install sphinx >> $LogFile 2>> $LogFile
    echo "extension=sphinx.so" > /etc/php5/conf.d/sphinx.ini
    cd $installDir/files/php5/pecl_http/
    echo -ne '\n' | phpize >> $LogFile 2>> $LogFile
    echo -ne '\n' | ./configure >> $LogFile 2>> $LogFile
    echo -ne '\n' | make >> $LogFile 2>> $LogFile
    echo -ne '\n' | make install >> $LogFile 2>> $LogFile
    echo "extension=http.so" > /etc/php5/conf.d/http.ini
    /etc/init.d/apache2 restart > /dev/null 2>&1
    echo -e "${Green} Done.${NC}"

### Installing additional PHP modules here ###
    #Print here info about php modules

    #tidy
    tidyenabled=`php -r phpinfo\(\)\; | grep -A 4 'tidy' | grep 'Tidy support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $tidyenabled -gt 0 ]]; then
        tidyisenabled="true"
    else tidyisenabled="false"
    fi
    tidyver=`php -r phpinfo\(\)\; | grep -A 4 'tidy' | grep 'Extension Version'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-tidy version: ${Yellow}$tidyver.${Purple} Is enabled: ${Yellow}$tidyisenabled.${NC}"

    #redis
    redisenabled=`php -r phpinfo\(\)\; | grep -A 3 'redis' | grep 'Redis Support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $redisenabled -gt 0 ]]; then
        redisisenabled="true"
    else redisisenabled="false"
    fi
    redisver=`php -r phpinfo\(\)\; | grep -A 3 'redis' | grep 'Redis Version'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-redis version: ${Yellow}$redisver.${Purple} Is enabled: ${Yellow}$redisisenabled.${NC}"

    #memcache
    memcacheenabled=`php -r phpinfo\(\)\; | grep -A 4 'memcache' | grep 'memcache support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $memcacheenabled -gt 0 ]]; then
        memcacheisenabled="true"
    else memcacheisenabled="false"
    fi
    memcachever=`php -r phpinfo\(\)\; | grep -A 4 'memcache' | grep 'Version' -m 1| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-memcache version: ${Yellow}$memcachever.${Purple} Is enabled: ${Yellow}$memcacheisenabled.${NC}"

    #memcached
    memcachedenabled=`php -r phpinfo\(\)\; | grep -A 4 'memcached' | grep 'memcached support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $memcachedenabled -gt 0 ]]; then
        memcachedisenabled="true"
    else memcachedisenabled="false"
    fi
    memcachedver=`php -r phpinfo\(\)\; | grep -A 4 'memcached' | grep 'Version' | awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-memcached version: ${Yellow}$memcachedver.${Purple} Is enabled: ${Yellow}$memcachedisenabled.${NC}"

    #geoip
    geoipenabled=`php -r phpinfo\(\)\; | grep -A 3 'geoip' | grep 'geoip support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $geoipenabled -gt 0 ]]; then
        geoipisenabled="true"
    else geoipisenabled="false"
    fi
    geoipver=`php -r phpinfo\(\)\; | grep -A 3 'geoip' | grep 'geoip extension version' | awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-geoip version: ${Yellow}$geoipver.${Purple} Is enabled: ${Yellow}$geoipisenabled.${NC}"

    #sphinx
    sphinxenabled=`php -r phpinfo\(\)\; | grep -A 2 'sphinx' | grep 'sphinx support'| awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' ' | grep 'enabled' | wc -l`
    if [[ $sphinxenabled -gt 0 ]]; then
        sphinxisenabled="true"
    else sphinxisenabled="false"
    fi
    sphinxver=`php -r phpinfo\(\)\; | grep -A 3 'sphinx' | grep 'Version' | awk 'BEGIN{FS="=>"}{print $2}' | tr -d ' '`
    echo -e "${Purple}php5-sphinx version: ${Yellow}$sphinxver.${Purple} Is enabled: ${Yellow}$sphinxisenabled.${NC}"

    #ioncube
    ioncubeenabled=`php -r phpinfo\(\)\; | grep 'with the ionCube' | wc -l`
    if [[ $ioncubeenabled -gt 0 ]]; then
        ioncubeisenabled="true"
    else ioncubeisenabled="false"
    fi
    ioncubever=`php -r phpinfo\(\)\; | grep 'with the ionCube' | awk 'BEGIN{FS=" "}{print $6}' | awk 'BEGIN{FS=","}{print $1}'`
    echo -e "${Purple}IonCube Loader version: ${Yellow}$ioncubever.${Purple} Is enabled: ${Yellow}$ioncubeisenabled.${NC}"

    echo ""
fi
else
    echo ""
fi

### PHPMyAdmin installation ###
echo -en "${Cyan}"
read -p "Do you want to install phpmyadmin? [Y/n] : " phpmyadminInst
echo -en "${NC}"
if [[ "$phpmyadminInst" != "n" && "$apacheInst" != "n" && "$mySQLInst" != "n" && "$PHPInst" != "n" ]]; then
    echo ""
    echo -e "${Green}  +------------------------------------+${NC}"
    echo -e "${Green}  |      Installing ${Yellow}phpmyadmin  ${Green}       |${NC}"
    echo -e "${Green}  +------------------------------------+${NC}"
    echo ""

    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/mysql/admin-pass password $$sqlrootPass" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/mysql/app-pass password $$sqlrootPass" |debconf-set-selections
	echo "phpmyadmin phpmyadmin/app-password-confirm password $$sqlrootPass" | debconf-set-selections
    echo -en "${Purple}Installing phpmyadmin .${NC}"
	apt-get -q -y install phpmyadmin >> $LogFile 2>> $LogFile
    counter=3
    while [[ "$counter" -gt 0 ]]; do
        echo -en "${Purple}.${NC}"
        counter=$((counter - 1))
        sleep 1
    done
    echo -e "${Green} Done.${NC}"
fi

### Installation complete ###
echo ""
echo -e "${Green}  +-----------------------------------------+${NC}"
echo -e "${Green}  | ${Yellow}Congratulations!${Green} Installation complete. |${NC}"
echo -e "${Green}  | Here are some details:                  |${NC}"
echo -e "${Green}  +-----------------------------------------+${NC}"
echo ""

echo "" >> $LogFile
echo "+-----------------------------------------+" >> $LogFile
echo "| Congratulations! Installation complete. |" >> $LogFile
echo "+-----------------------------------------+" >> $LogFile
echo "" >> $LogFile

echo -e "${Purple}Installation Directory : ${Yellow}$installDir${NC}"
if [[ "$mySQLInst" != "n" ]]; then
    echo -e "${Purple}MySQL Server Root Password : ${Red}$sqlrootPass${NC}"
    mysqlver=`dpkg -l | grep 'MySQL database server binaries and system database setup' | awk '{print $3}'`
    echo -e "${Purple}MySQL Server version installed: ${Yellow}$mysqlver${NC}"
fi
if [[ "$apacheInst" != "n" ]]; then
    apachever=`dpkg -l | grep 'Apache HTTP Server common binary files' | awk '{print $3}'`
    echo -e "${Purple}Apache version installed: ${Yellow}$apachever${NC}"
    if [[ "$apacheInstNginx" != "n" ]]; then
        nginxver=`dpkg -l | grep 'small, powerful, scalable web/proxy server' | awk '{print $3}' | xargs | awk '{print $1}'`
        echo -e "${Purple}Nginx version installed: ${Yellow}$nginxver${NC}"
    fi
fi
if [[ "$PHPInst" != "n" ]]; then
    echo -e "${Purple}PHP version installed: ${Yellow}$phpver${NC}"
fi
echo ""

echo -en "${Cyan}"
read -p "Do you want to start services? [Y/n] : " StartServices
echo -en "${NC}"
if [[ "$StartServices" != "n" ]]; then
    if [[ "$apacheInst" != "n" ]]; then
        echo -en "${Purple}Starting Apache.${NC}"
        counter=3
        while [[ $counter -gt 0 ]]; do
            echo -en "${Purple}.${NC}"
            counter=$((counter - 1))
            sleep 1
        done
        echo -en "${Green} Done.${NC}"
        echo ""
    fi
    if [[ "$apacheInst" != "n" && "$apacheInstNginx" != "n" ]]; then
        echo -en "${Purple}Starting Nginx.${NC}"
        counter=3
        while [[ $counter -gt 0 ]]; do
            echo -en "${Purple}.${NC}"
            counter=$((counter - 1))
            sleep 1
        done
        echo -en "${Green} Done.${NC}"
        echo ""
    fi
    if [[ "$mySQLInst" != "n" ]]; then
        echo -en "${Purple}Starting MySQL Server.${NC}"
        counter=3
        while [[ $counter -gt 0 ]]; do
            echo -en "${Purple}.${NC}"
            counter=$((counter - 1))
            sleep 1
        done
        echo -en "${Green} Done.${NC}"
        echo ""
    fi
else
    if [[ "$apacheInst" != "n" ]]; then
        /etc/init.d/apache2 stop  > /dev/null 2>&1
    fi
    if [[ "$apacheInst" != "n" && "$apacheInstNginx" != "n" ]]; then
        /etc/init.d/nginx stop  > /dev/null 2>&1
    fi
    if [[ "$mySQLInst" != "n" ]]; then
        /etc/init.d/mysql stop  > /dev/null 2>&1
    fi
fi

echo ""
echo -en "${Cyan}"
read -p "Do you want to install VmWare tools? [Y/n] : " VmWaretoolsInstall
echo -en "${NC}"
if [[ "$VmWaretoolsInstall" != "n" ]]; then
    echo -en "${Purple}Installing VmWare Tools .${NC}"
    cd $installDir
    wget --connect-timeout=10 -t 2 -T 120 http://files.pashaxp.com/vm-tools.tar.gz > /dev/null 2>&1
    tar xzvf vm-tools.tar.gz > /dev/null 2>&1
    cd vmware-tools-distrib/
    if [[ $? -ne 0 ]]; then
        echo -e "${Red}Error during extracting. VmWare Tools are not installed.${NC}\\n"
    else
        ./vmware-install.pl --default EULA_AGREED=yes > /dev/null 2>&1
        if [[ "$VmWaretoolsInstall" != "n" ]]; then
            counter=3
            while [[ "$counter" -gt 0 ]]; do
                echo -en "${Purple}.${NC}"
                counter=$((counter - 1))
                sleep 1
            done
        fi
        echo -e "${Green} Done.${NC}"
    fi
fi
cd "$installDir"

### Add system users ###
SysUserAdd="Y"
while [[ "$SysUserAdd" = "Y" ]]; do
echo ""
echo -en "${Cyan}"
read -p "Do you want to add a system user? [Y/N] : " SysUserAddConfirm
echo -en "${NC}"
SysUserAdd=`echo $SysUserAddConfirm | awk '{print toupper($0)}'`
if [[ "$SysUserAdd" = "Y" ]]; then
    echo ""
    echo -en "${Cyan}"
    read -p "Enter a system user NAME: " SysUserAddName
    echo -en "${NC}"
    if [[ ! -z $SysUserAddName ]]; then
        adduser $SysUserAddName
        echo -en "${Cyan}"
        read -p "Do you want to add this user into the sudoers file? [Y/N] : " SysUserAddSudo
        echo -en "${NC}"
        if [[ "$SysUserAddSudo" != "n" ]]; then
            echo "$SysUserAddName   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;
        fi
    fi
fi
done

### Credits ###
echo ""
echo -e "${Green}  +--------------------------------------+${NC}"
echo -e "${Green}  | ${Yellow}Thank you${Green} for choosing our services! |${NC}"
echo -e "${Green}  +--------------------------------------+${NC}"
echo ""
echo "" >> $LogFile
echo "+--------------------------------------+" >> $LogFile
echo "| Thank you for choosing our services! |" >> $LogFile
echo "+--------------------------------------+" >> $LogFile
echo "" >> $LogFile

echo -e "${Purple}Everything is done. Cleaning temp dir ${Red}$installDir${Purple}.${NC}"
if [[ "$IsLogging" != "n" ]]; then
    cleanup
    echo -en "${Purple}Logfile has been saved to ${Red}$LogFile${Purple}. ${NC}"
fi

echo -en "${Purple}Exiting ."
counter=3
while [[ $counter -gt 0 ]]; do
    echo -en "${Purple}.${NC}"
    counter=$((counter - 1))
    sleep 1
done
echo -en "${Green} Done.${NC}"
echo ""; echo ""

exit 0
done
__TARFILE_FOLLOWS__