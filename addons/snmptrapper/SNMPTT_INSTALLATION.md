# SNMPTT

>**NOTE**: This simple example uses SNMPTT as a traphandle. For better performance on production systems, use embedded Perl to pass traps from snmptrapd to SNMPTT.


The "snmptt"  service will serve as a traphandle.

1. Install the "snmptt" package and its dependencies.

```bash
  apt-get install snmptt libconfig-inifiles-perl libsnmp-perl
```

2. Configure the "snmptt" service. We will add Perl support and adjust log and date settings.

Edit in the "General" section of the file.

```bash
  vim /etc/snmp/snmptt.ini
```

```
[General]

 # ## Enable the us  of the Perl module from the NET-SNMP package:
 net_snmp_perl_enable = 1

 # ## Configure output file and time format:
 date_time_format = %H:%M:%S %Y/%m/%d

[Logging]

 # ## Log file location.  The COMPLETE path and filename.  Ex: '/var/log/snmptt/snmptt.log'
 log_file = /var/log/snmptt/snmptt.log
```

>**WARNING**: Remember to logrotate the snmptt.log file if you change its destination.

By default, the configuration should look like this.

```bash
  cat /etc/logrotate.d/snmptt
```

```
/var/log/snmptt/*.log /var/log/snmptt/*.debug {
        missingok
        notifempty
        weekly
        rotate 4
        compress
        sharedscripts
        postrotate
                /etc/init.d/snmptt reload > /dev/null
        endscript
}
```

3. Do the activation, the restart of the snmptt service.

```bash
  systemctl enable snmptt.service
  systemctl restart snmptt.service
  systemctl status snmptt.service
```


## Spooler files

You can then confirm the spooled files have been processed with the following command:

```bash
  ls -al /var/spool/snmptt/
```

Which should show an empty directory listing.
