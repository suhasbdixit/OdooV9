#!/bin/bash
################################################################################
# Script for Installation: ODOO V8 server on Ubuntu Server 
# Author: André Schenkels, ICTSTUDIO 2014
# Forked & Modified by: Swapnil A. Wagh
#-------------------------------------------------------------------------------
#  
# This script will install ODOO V8 on
# clean Ubuntu Server
#-------------------------------------------------------------------------------
# USAGE:
#
# odoo-install
#
# EXAMPLE:
# sudo ./odoo-install 
#
################################################################################
 

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
	echo -e "This script must be run as root" 1>&2
	exit 1
fi

##fixed parameters
#openerp
OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/$OE_USER-server"
# Replace for openerp-gevent for enabling gevent mode for chat
OE_SERVERTYPE="openerp-server"


#set the superadmin password
OE_SUPERADMIN="admin"
OE_CONFIG="$OE_USER-server"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get upgrade -y
sudo apt-get update -y
	
#--------------------------------------------------
# Set Locale en_US.UTF-8
#--------------------------------------------------
echo -e "\n---- Set en_US.UTF-8 Locale ----"
sudo cp /etc/default/locale /etc/default/locale.BACKUP
sudo rm -rf /etc/default/locale
echo -e "* Change server config file"
sudo su root -c "echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale"
sudo su root -c "echo 'LANG="en_US.UTF-8"' >> /etc/default/locale"
sudo su root -c "echo 'LANGUAGE="en_US:en"' >> /etc/default/locale"

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y  

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install git bzr bzrtools python-pip -y

echo -e "\n---- Install and Upgrade pip and virtualenv ----"
sudo apt-get install python-dev build-essential -y
sudo pip install --upgrade pip
echo -e "\n---- Install pyserial and qrcode for compatibility with hw_ modules for peripheral support in Odoo ---"
sudo pip install pyserial qrcode pytz jcconv
sudo apt-get -f install -y

echo -e "\n---- Install pyusb 1.0+ not stable for compatibility with hw_escpos for receipt printer and cash drawer support in Odoo ---"
sudo pip install --pre pyusb
	
echo -e "\n---- Install python packages ----"
sudo apt-get install -y --force-yes --no-install-recommends python-gevent python-dateutil python-feedparser python-gdata python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-pdftools python-setuptools python-pybabel python-imaging python-matplotlib python-reportlab-accel python-openssl python-egenix-mxdatetime python-paramiko antiword python-decorator poppler-utils python-requests libpq-dev python-geoip python-markupsafe postgresql-client python-passlib vim libreoffice curl openssh-server npm python-cairo python-genshi libreoffice-script-provider-python

# Install NodeJS and Less compiler needed by Odoo 8 Website - added from https://gist.github.com/rm-jamotion/d61bc6525f5b76245b50
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install nodejs -y
npm install less -y

echo -e "\n---- Install python libraries ----"
sudo pip install gdata
sudo pip install passlib

echo -e "\n---- Install Other Dependencies ----"
sudo pip install graphviz ghostscript gcc mc bzr lptools make
sudo pip install gevent gevent_psycopg2 psycogreen

echo -e "\n---- Install Wkhtmltopdf 0.12.1 ----"
sudo wget http://downloads.sourceforge.net/project/wkhtmltopdf/archive/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin
	
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir -p /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo su $OE_USER -c "mkdir -p $OE_HOME_EXT"
sudo wget http://nightly.odoo.com/8.0/nightly/src/odoo_8.0.latest.tar.gz -O $OE_USER.tar.gz
sudo tar -xvzf $OE_USER.tar.gz -C $OE_HOME_EXT --strip-components 1
echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir -p $OE_HOME_EXT/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"

if [ -f "/etc/$OE_CONFIG.conf" ]
then
	sudo rm /etc/$OE_CONFIG.conf
fi

sudo touch /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Change server config file"
sudo su root -c "echo '[options]' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'addons_path = $OE_HOME_EXT/openerp/addons,$OE_HOME_EXT/addons' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'admin_passwd = $OE_SUPERADMIN' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'auto_reload = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'csv_internal_sep = ,' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'data_dir = $OE_HOME/.local/share/Odoo' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Database Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_host = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_maxconn = 64' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_name = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_password = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_port = 5432' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'db_template = template1' >> /etc/$OE_CONFI	G.conf"
sudo su root -c "echo 'db_user = $OE_USER' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'dbfilter = .*' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Logging Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'log_db = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'log_handler = [':INFO']' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'log_level = info' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logrotate = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'longpolling_port = 8072' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## XMLRPC Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc_interface = ' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc_port = 8069' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs_interface =' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs_port = 8071' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## SSL Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'secure_cert_file = server.cert' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'secure_pkey_file = server.pkey' >> /etc/$OE_CONFIG.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/$OE_SERVERTYPE --config=/etc/$OE_CONFIG.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"

if [ -f "~/$OE_CONFIG" ]
then
	sudo rm ~/$OE_CONFIG
fi

echo '#!/bin/sh' >> ~/$OE_CONFIG
echo '### BEGIN INIT INFO' >> ~/$OE_CONFIG
echo '# Provides: $OE_CONFIG' >> ~/$OE_CONFIG
echo '# Required-Start: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Required-Stop: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Should-Start: $network' >> ~/$OE_CONFIG
echo '# Should-Stop: $network' >> ~/$OE_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$OE_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$OE_CONFIG
echo '# Short-Description: Enterprise Business Applications' >> ~/$OE_CONFIG
echo '# Description: ODOO Business Applications' >> ~/$OE_CONFIG
echo '### END INIT INFO' >> ~/$OE_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/$OE_CONFIG
echo "DAEMON=$OE_HOME_EXT/$OE_SERVERTYPE" >> ~/$OE_CONFIG
echo "NAME=$OE_CONFIG" >> ~/$OE_CONFIG
echo "DESC=$OE_CONFIG" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify the user name (Default: odoo).' >> ~/$OE_CONFIG
echo "USER=$OE_USER" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$OE_CONFIG
echo "CONFIGFILE=\"/etc/$OE_CONFIG.conf\"" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# pidfile' >> ~/$OE_CONFIG
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Additional options that are passed to the Daemon.' >> ~/$OE_CONFIG
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/$OE_CONFIG
echo '[ -x $DAEMON ] || exit 0' >> ~/$OE_CONFIG
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/$OE_CONFIG
echo 'checkpid() {' >> ~/$OE_CONFIG
echo '[ -f $PIDFILE ] || return 1' >> ~/$OE_CONFIG
echo 'pid=`cat $PIDFILE`' >> ~/$OE_CONFIG
echo '[ -d /proc/$pid ] && return 0' >> ~/$OE_CONFIG
echo 'return 1' >> ~/$OE_CONFIG
echo '}' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'case "${1}" in' >> ~/$OE_CONFIG
echo 'start)' >> ~/$OE_CONFIG
echo 'echo -n "Starting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo 'stop)' >> ~/$OE_CONFIG
echo 'echo -n "Stopping ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'restart|force-reload)' >> ~/$OE_CONFIG
echo 'echo -n "Restarting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'sleep 1' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '*)' >> ~/$OE_CONFIG
echo 'N=/etc/init.d/${NAME}' >> ~/$OE_CONFIG
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/$OE_CONFIG
echo 'exit 1' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'esac' >> ~/$OE_CONFIG
echo 'exit 0' >> ~/$OE_CONFIG

echo -e "* Security Init File"

if [ -f "/etc/init.d/$OE_CONFIG" ]
then
	sudo rm /etc/init.d/$OE_CONFIG
fi
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Create service   sudo service $OE_SERVERTYPE start"
sudo update-rc.d $OE_SERVERTYPE defaults

echo -e "* Open ports in UFW for openerp-gevent"
sudo ufw allow 8072
echo -e "* Open ports in UFW for openerp-server"
sudo ufw allow 8069

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults
sudo service $OE_CONFIG start

echo "Done! The ODOO server can be started with /etc/init.d/$OE_CONFIG"
echo "Please reboot the server now so that Wkhtmltopdf is working with your install."
echo "Once you've rebooted you'll be able to access your Odoo instance by going to http://[your server's IP address]:8069"
echo "For example, if your server's IP address is 192.168.1.123 you'll be able to access it on http://192.168.1.123:8069"
