![alt text][logo]

# Cybionet - Ugly Codes Division

## SUMMARY

Zabbix Server service installation script under Ubuntu and Debian.

You can choose between different options, such as:
- the Zabbix Server version supported by your distribution.
- the source repository of the package (Zabbix or the distribution).

Works on Ubuntu, Debian and Rasbpian.


## REQUIRED

The `vx_zbxserver.sh` application does not require any additional packages to work.


## INSTALLATION

1. Download files from this repository directly with git or via https.
	```bash
	wget -O svc_zabbixserver.zip https://github.com/cybiohub/svc_zabbixserver/archive/refs/heads/main.zip
	```

2. Unzip the zip file.
	```bash
	unzip svc_zabbixserver.zip
	```

3. Make changes to the installation script `vx_zbxserver.sh` to configure it to match your environment.
	
	You can customize the following settings: 

	- Choose between Zabbix repository version or distribution version. By default, this is the Zabbix repository version.
	- The version of Zabbix Server you want to install.
	- Directory location for additional scripts. By default in `/opt/zabbix`.

4. Once completed, set the `Configured` parameter to `true`.

5. Adjust permissions.
	```bash
	chmod 500 vx_zbxserver.sh
	```

6. Run the script.
	```bash
	./vx_zbxserver.sh
	```

7. Configure Zabbix Server service.
	```bash
	vim /etc/zabbix/zabbix_server.conf
	```
	```
	# ## Name of the database.
	DBName=zabbix

	# ## User of the database.
	DBUser=zabbix

	# ## Password for the database.
	DBPassword=SECRETPASSWORD
	```

8. Create the MySQL database manually.

       ```bash
	mysql -p -e "create database zabbix character set utf8 collate utf8_bin;"
	mysql -p -e "grant all on zabbix.* to 'zabbix'@'localhost' identified by 'SECRETPASSWORD';"
	exit;
       ```

9. Populate Zabbix database.

For a version from the Zabbix repository,

       ```bash
	zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -p zabbix
       ```

For a version from the Ubuntu/Debian repository,

       ```bash
	zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql -u zabbix -p zabbix

	zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql -u zabbix -p zabbix

	zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql -u zabbix -p zabbix
       ```

10. Activate and start the Zabbix server service.
	```bash
	systemctl enable zabbix-server.service
	systemctl start zabbix-server.service
	systemctl status zabbix-server.service
	```

11. To finish the configurate the frondend, access to http://W.X.Y.Z/zabbix/.

---
[logo]: ./md/logo.png "Cybionet"

