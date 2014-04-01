#!/usr/bin/env bash 

LOG="$PWD/log.$(date +"%Y-%m-%dT%H:%m")"

# To handle global redirection
#exec 3>&1 4>&2 >>$LOG 2>&1
#exec 1>&3 2>&4

#
# Update packages and installed required package for Nagios
#
echo "Updating packages..."
sudo yum update >> $LOG 2>&1
echo "Installing required packages for Nagios..."
sudo yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp >> $LOG 2>&1

#
# Add the nagios user and groups
#
NAGIOS_USER=nagios
NAGIOS_GROUP=nagios
NAGIOS_CMD_GROUP=nagcmd
echo "Add required users and groups"
sudo useradd ${NAGIOS_USER} >> $LOG 2>&1
groupadd ${NAGIOS_CMD_GROUP} >> $LOG 2>&1
usermod -a -G ${NAGIOS_CMD_GROUP} ${NAGIOS_USER} >> $LOG 2>&1

#
# Download the Nagios distribution
#

echo "Downloading Nagios core and plugins..."

NAGIOS_CORE_DIR="nagios-3.5.1"
NAGIOS_PLUGINS_DIR="nagios-plugins-2.0"
NAGIOS_CORE_TAR="${NAGIOS_CORE_DIR}.tar.gz"
NAGIOS_PLUGINS_TAR="${NAGIOS_PLUGINS_DIR}.tar.gz"

# Nagios core
wget http://prdownloads.sourceforge.net/sourceforge/nagios/${NAGIOS_CORE_TAR} >> $LOG 2>&1

# Nagios plugins
wget http://nagios-plugins.org/download/${NAGIOS_PLUGINS_TAR} >> $LOG 2>&1

# Extract
echo "Extract Nagios core and plugins..."
tar xvf "${NAGIOS_CORE_TAR}" >> $LOG 2>&1
tar xvf "${NAGIOS_PLUGINS_TAR}" >> $LOG 2>&1

#
# Create directory to install Nagios
#
echo "Create Nagios install directory..."
NAGIOS_INSTALL=/usr/local/nagios
NAGIOS_INSTALL_PERM=0755
sudo mkdir ${NAGIOS_INSTALL} >> $LOG 2>&1 
sudo chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL} >> $LOG 2>&1
sudo chmod ${NAGIOS_INSTALL_PERM} ${NAGIOS_INSTALL} >> $LOG 2>&1

# Build and install Nagios

pushd nagios > /dev/null 2>&1
echo "Build Nagios..."
./configure --with-command-group=${NAGIOS_CMD_GROUP}  >> $LOG 2>&1
make all >> $LOG 2>&1
echo "Install Nagios..."
make install >> $LOG 2>&1
sudo make install-init >> $LOG 2>&1
make install-config >> $LOG 2>&1
make install-commandmode >> $LOG 2>&1
sudo make install-webconf  >> $LOG 2>&1
# Copy contributions
echo "Install contributed event handlers..."
cp -R contrib/eventhandlers ${NAGIOS_INSTALL}/libexec >> $LOG 2>&1
sudo chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL}/libexec/eventhandlers >> $LOG 2>&1
popd > /dev/null 2>&1

echo "Validate nagios configuration..."
${NAGIOS_INSTALL}/bin/nagios -v ${NAGIOS_INSTALL}/etc/nagios.cfg >> $LOG 2>&1

# Start the Nagios and httpd services
echo "Start nagios and httpd..."
sudo /etc/init.d/nagios start >> $LOG 2>&1

sudo /etc/init.d/httpd start >> $LOG 2>&1

# Define our administrative user and password
echo "Configure nagios admin..."
htpasswd -b -c ${NAGIOS_INSTALL}/etc/htpasswd.users nagiosadmin nagios123 >> $LOG 2>&1

echo "Build Nagios plugins..."
pushd "${NAGIOS_PLUGINS_DIR}" >> $LOG 2>&1
./configure --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_GROUP} >> $LOG 2>&1
make  >> $LOG 2>&1
make install >> $LOG 2>&1
popd  >> $LOG 2>&1


# Configure startup
echo "Configuring nagios and httpd startup..."
sudo chkconfig --add nagios >> $LOG 2>&1
sudo chkconfig --level 35 nagios on >> $LOG 2>&1
sudo chkconfig --add httpd >> $LOG 2>&1
sudo chkconfig --level 35 httpd on >> $LOG 2>&1

echo "Details of the installation have been logged to $LOG"

