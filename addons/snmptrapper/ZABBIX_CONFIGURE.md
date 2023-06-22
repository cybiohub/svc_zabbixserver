# Zabbix and Trap SNMP

## Workflow

Reference: https://www.zabbix.com/documentation/current/manual/config/items/itemtypes/snmptrap

The workflow of receiving a trap:

1. snmptrapd receives a trap

2. snmptrapd passes the trap to SNMPTT or calls Perl trap receiver

3. SNMPTT or Perl trap receiver parses, formats and writes the trap to a file

4. Zabbix SNMP trapper reads and parses the trap file

5. For each trap Zabbix finds all "SNMP trapper" items with host interfaces matching the received trap address. Note that only the selected “IP” or “DNS” in host interface is used during the matching.

6. For each found item, the trap is compared to regexp in "snmptrap[regexp]". The trap is set as the value of all matched items. If no matching item is found and there is an "snmptrap.fallback" item, the trap is set as the value of that.

7. If the trap was not set as the value of any item, Zabbix by default logs the unmatched trap. (This is configured by "Log unmatched SNMP traps" in Administration → General → Other.)
<br>
## SNMPTT configuration

1. On the Zabbix Server/Proxy, make sure you have opened the UDP/162 port.

```bash
iptables -A INPUT -p udp -m udp --dport 162 -j ACCEPT
```

2. Configure traps file to add Zabbix section.

At the very end of the file.

```bash
vim /etc/snmp/snmptt.conf
```

add

```
# ## General event
EVENT general .* "General event" Normal
FORMAT ZBXTRAP $aR $N $+*

# ## date time trap-OID severity category hostname - format
# ## FORMAT ZBXTRAP $aR $N "$+*"
# ## $aR, $ar - IP address
# ## $N  - Event name defined in .conf file of matched entry
# ## $+*  - Expand all variable-bindings in the format of variable name:value
```

3. Restart the "snmptt" service.

```bash
systemctl restart snmptt.service
systemctl status snmptt.service
```
<br>
# Configuration

For configuring SNMP trap support on Zabbix Servers or Proxy.

```bash
vim /etc/zabbix/zabbix_proxy.conf
```

```
# ########### TRAP SNMP ##########################
StartSNMPTrapper=1

# ## Match the settings in snmptt.ini too.
# ## vim /etc/snmp/snmptt.ini
# ## log_file = /var/log/snmptt/snmptt.log
SNMPTrapperFile=/var/log/snmptt/snmptt.log
```

>**NOTE**: If the "PrivateTmp" parameter in systemd is used, this file is unlikely to work in the /tmp directory.
<br>
## Items

Here are some sample configuration items and snmp queries to generate verification traps.

### Example #1

Item configuration.

```
Name:                   Trap SNMP - Catch All
Type:                   SNMP trap
Key:                    snmptrap.fallback
Host interface:         127.0.0.1:161
Type of information:    Text
```

Generation of an SNMP Trap.

```bash
snmptrap -v 1 -c public 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "teststring000"

  15:59:42 2021/05/05 .1.3.6.1.6.3.1.1.5.3.0.33 Normal "General event" localhost - ZBXTRAP 127.0.0.1 127.0.0.1
```

### Example #2

Item configuration.

```
Name:                   Trap SNMP - General
Type:                   SNMP trap
Key:                    snmptrap["General"]
Host interface:         127.0.0.1:161
Type of information:    Log

Log time format:        hh:mm:ss yyyy/MM/dd
Application:            Trap SNMP
```

Generation of an SNMP Trap.

```bash
snmptrap -v 1 -c public 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "General event"

  15:59:42 2021/05/05 .1.3.6.1.6.3.1.1.5.3.0.33 Normal "General event" localhost - ZBXTRAP 127.0.0.1 127.0.0.1
```
<br>
## Vérification in Zabbix

Requires the snmptrap command to be installed through the "snmp" package.

```bash
apt-get install snmp
```

>**NOTE**: "Each FORMAT statement should start with "ZBXTRAP [address]", where [address] will be compared to IP and DNS addresses of SNMP interfaces on Zabbix".

Host's SNMP interface IP: 127.0.0.1
Key: snmptrap["General"]
Log time format: hh:mm:ss yyyy/MM/dd

```
This results in:

Command used to send a trap:
```bash
snmptrap -v 1 -c public 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "teststring000"
```

The received trap:

```
13:58:58 2022/02/01 .1.3.6.1.6.3.1.1.5.3.0.33 Normal "General event" localhost - ZBXTRAP 127.0.0.1 127.0.0.1
```

```bash
cat /var/log/snmptt/snmptt.log
13:58:58 2022/02/01 .1.3.6.1.6.3.1.1.5.3.0.33 Normal "General event" localhost - ZBXTRAP 127.0.0.1 general .iso:teststring000
```
