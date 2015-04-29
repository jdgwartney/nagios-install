# Nagios Virtual Machine
Uses vagrant to create a CentOS 6.5 VM and install with Nagios 3.51 core

## Requirements
- Vagrant (http://www.vagrantup.com/downloads.html)
- Virtualbox (https://www.virtualbox.org/wiki/Downloads)

## Instructions

### Startup

1. Start the virtual machine ```$ vagrant up```
2. Wait until the virtual machines starts and completes provisioning
3. Open your web browser to `http://localhost:8080/nagios`
4. Credentials `nagiosadmin:nagios123`.
5. To login onto the host: ```$ vagrant ssh```

### Login as the Nagios User
The nagios unix user password is `nagios`.
NOTE: Vagrant performs the port forwarding from 2222 to 22.

1. ```ssh -l nagios -p 2222 localhost```

### Suspend
Saves the state of the VM on disk so it can be resumed later

1. ```vagrant suspend```

### Resume
Restarts VM from its preserved state.

1. ```vagrant resume```

### Shutdown
Completely destroys the VM and it state, but it also
frees up all the disk usage associated with the VM instance.

1. Stop and destroy the virtual machine ```$ vagrant destroy```






