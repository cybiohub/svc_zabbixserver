# Installation

1. Assignment of the correct permissions on the script.

```bash
  chown root:root zbxserverchecker.sh
  chmod 500 zbxserverchecker.sh

```

2. Move the script to its final location.

```bash
  mv zbxserverchecker.sh /opt/zabbix/checker
```

3. Add the following value to the crontab.

```bash
  vim /etc/cron.d/zbxserverchecker
```

```
 # Zabbix Server Checker
 */10 * * * * root /opt/zabbix/checker/zbxserverchecker.sh >/dev/null 2>&1

```

## Additional note

1. Required to use email. Why mutt? Because it work with Outlook 365 and GMail.

```bash
  apt-get install mutt
```

2. Required if you want to use SMS.

```bash
  apt-get install smsclient
```
