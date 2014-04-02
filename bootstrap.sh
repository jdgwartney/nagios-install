#!/usr/bin/env bash 

#
# Create a path to a log file that encodes
# into the path the date and time to minute resolution
#
LOG="$PWD/log.$(date +"%Y-%m-%dT%H:%m")"

# To handle global redirection
#exec 3>&1 4>&2 >>$LOG 2>&1
#exec 1>&3 2>&4

log() {
  typeset -r msg=$1
  echo "$(date): $msg"
}

#
# Update packages 
#
log "Updating packages..."
sudo yum update >> $LOG 2>&1

#
# Packages for sane administration
#
log "Installing system adminstration packages..."
sudo yum install -y man wget >> $LOG 2>&1

log "Install epel gpg keys and epel-release package..."
wget https://fedoraproject.org/static/0608B895.txt >> $LOG 2>&1
sudo mv 0608B895.txt /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm -ivh http://mirrors.mit.edu/epel/6/x86_64/epel-release-6-8.noarch.rpm >> $LOG 2>&1

#
# Install packages required for Nagios
#
log "Installing required packages for Nagios..."
sudo yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp >> $LOG 2>&1

#
# Required packages for RVM
#
log "Install required packages for RVM..."
sudo yum install -y patch libyaml-devel libffi-devel autoconf gcc-c++ patch readline-devel openssl-devel automake libtool bison >> $LOG 2>&1

#
# Required packages for Boundary Event Integration
#
log "Install required packages for Boundary Event Integration..."
sudo yum install -y curl unzip >> $LOG 2>&1

#
# Add the nagios user and groups
#
NAGIOS_USER=nagios
NAGIOS_GROUP=nagios
NAGIOS_CMD_GROUP=nagcmd
log "Add required users and groups..."
sudo useradd ${NAGIOS_USER} >> $LOG 2>&1
groupadd ${NAGIOS_CMD_GROUP} >> $LOG 2>&1
usermod -a -G ${NAGIOS_CMD_GROUP} ${NAGIOS_USER} >> $LOG 2>&1
echo "nagios" | sudo passwd nagios --stdin >> $LOG 2>&1

#
# Download the Nagios distribution
#

log "Downloading Nagios core and plugins..."

NAGIOS_CORE_DIR="nagios-3.5.1"
NAGIOS_PLUGINS_DIR="nagios-plugins-2.0"
NAGIOS_CORE_TAR="${NAGIOS_CORE_DIR}.tar.gz"
NAGIOS_PLUGINS_TAR="${NAGIOS_PLUGINS_DIR}.tar.gz"

# Nagios core
wget http://prdownloads.sourceforge.net/sourceforge/nagios/${NAGIOS_CORE_TAR} >> $LOG 2>&1

# Nagios plugins
wget http://nagios-plugins.org/download/${NAGIOS_PLUGINS_TAR} >> $LOG 2>&1

# Extract
log "Extract Nagios core and plugins..."
tar xvf "${NAGIOS_CORE_TAR}" >> $LOG 2>&1
tar xvf "${NAGIOS_PLUGINS_TAR}" >> $LOG 2>&1

#
# Create directory to install Nagios
#
log "Create Nagios install directory..."
NAGIOS_INSTALL=/usr/local/nagios
NAGIOS_INSTALL_PERM=0755
sudo mkdir ${NAGIOS_INSTALL} >> $LOG 2>&1 
sudo chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL} >> $LOG 2>&1
sudo chmod ${NAGIOS_INSTALL_PERM} ${NAGIOS_INSTALL} >> $LOG 2>&1

# Build and install Nagios

pushd nagios > /dev/null 2>&1
log "Build Nagios..."
./configure --with-command-group=${NAGIOS_CMD_GROUP}  >> $LOG 2>&1
make all >> $LOG 2>&1
log "Install Nagios..."
make install >> $LOG 2>&1
sudo make install-init >> $LOG 2>&1
make install-config >> $LOG 2>&1
make install-commandmode >> $LOG 2>&1
sudo make install-webconf  >> $LOG 2>&1
# Copy contributions
log "Install contributed event handlers..."
cp -R contrib/eventhandlers ${NAGIOS_INSTALL}/libexec >> $LOG 2>&1
sudo chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL}/libexec/eventhandlers >> $LOG 2>&1
popd > /dev/null 2>&1

log "Validate nagios configuration..."
${NAGIOS_INSTALL}/bin/nagios -v ${NAGIOS_INSTALL}/etc/nagios.cfg >> $LOG 2>&1

# Start the Nagios and httpd services
log "Start nagios and httpd..."
sudo /etc/init.d/nagios start >> $LOG 2>&1

sudo /etc/init.d/httpd start >> $LOG 2>&1

# Define our administrative user and password
log "Configure nagios admin..."
htpasswd -b -c ${NAGIOS_INSTALL}/etc/htpasswd.users nagiosadmin nagios123 >> $LOG 2>&1

log "Build Nagios plugins..."
pushd "${NAGIOS_PLUGINS_DIR}" >> $LOG 2>&1
./configure --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_GROUP} >> $LOG 2>&1
make  >> $LOG 2>&1
make install >> $LOG 2>&1
popd  >> $LOG 2>&1


# Configure startup
log "Configuring nagios and httpd startup..."
sudo chkconfig --add nagios >> $LOG 2>&1
sudo chkconfig --level 35 nagios on >> $LOG 2>&1
sudo chkconfig --add httpd >> $LOG 2>&1
sudo chkconfig --level 35 httpd on >> $LOG 2>&1

log "Details of the installation have been logged to $LOG"

