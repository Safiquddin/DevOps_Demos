# Tomcat installation on EC2 instance

### Follow this article in **[YouTube](https://www.youtube.com/watch?v=m21nFreFw8A)**
### Prerequisites
1. EC2 instance with Java v1.8.x 

### Install Java
We will be using open java for our demo, Get latest version from http://openjdk.java.net/install/
```sh 
yum install java-1.8*
#yum -y install java-1.8.0-openjdk
```
### Install Apache Tomcat
Download tomcat packages from  https://tomcat.apache.org/download-80.cgi onto /opt on EC2 instance

Create Tomcat user with restricted permissions
This is the user the Tomcat service will run as.
```sh 
groupadd tomcat
useradd -s /sbin/nologin -g tomcat -d /opt/apache-tomcat-8.5.6 tomcat
passwd tomcat
```
Set the tomcat user as the owner of the $CATALINA_HOME folder.
```sh 
chown -R tomcat.tomcat /opt/apache-tomcat-8.5.6
```

Download Tomcat from the Apache website.
You'll need a terminal and root access.

```sh 
  # create tomcat directory
  cd /opt
  wget http://mirrors.fibergrid.in/apache/tomcat/tomcat-8/v8.5.35/bin/apache-tomcat-8.5.35.tar.gz
  tar -xvzf /opt/apache-tomcat-8.5.35.tar.gz
```
give executing permissions to startup.sh and shutdown.sh which are under bin. 
```sh
   chmod +x /opt/apache-tomcat-8.5.35/bin/startup.sh shutdown.sh
```

create link files for tomcat startup.sh and shutdown.sh 
```sh
  ln -s /opt/apache-tomcat-8.5.35/bin/startup.sh /usr/local/bin/tomcatup
  ln -s /opt/apache-tomcat-8.5.35/bin/shutdown.sh /usr/local/bin/tomcatdown
  tomcatup
```
#### check point :
access tomcat application from browser on prot 8080  
http://<Public_IP>:8080

Using unique ports for each application is a best practice in an environment. But tomcat and Jenkins runs on ports number 8080. Hence lets change tomcat port number to 8090. Change port number in conf/server.xml file under tomcat home
```sh
cd /opt/apache-tomcat-8.5.35/conf
# update port number in the "connecter port" field in server.xml
# restart tomcat after configuration update
tomcatdown
tomcatup
```
#### check point :
access tomcat application from browser on prot 8090  
http://<Public_IP>:8090

now application is accessible on port 8090. but tomcat application doesnt allow to login from browser. changing a default parameter in context.xml does address this issue
```sh
#search for context.xml
find / -name context.xml
```
above command gives 3 context.xml files. comment (<!-- & -->) `Value ClassName` field on files which are under webapp directory. 
After that restart tomcat services to effect these changes
```sh 
tomcatdown
tomcatup
```
Update users information in the tomcat-users.xml file
goto tomcat home directory and Add below users to conf/tomcat-user.xml file
```sh
	<role rolename="manager-gui"/>
	<role rolename="manager-script"/>
	<role rolename="manager-jmx"/>
	<role rolename="manager-status"/>
	<user username="admin" password="admin" roles="manager-gui, manager-script, manager-jmx, manager-status"/>
	<user username="deployer" password="deployer" roles="manager-script"/>
	<user username="tomcat" password="s3cret" roles="manager-gui"/>
```
Restart serivce and try to login to tomcat application from the browser. This time it should be Successful
Install Tomcat as a service on Linux
Using systemd
Add /etc/systemd/system/tomcat.service init script:

# Systemd unit file for tomcat
```sh
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking


Environment=CATALINA_PID=/opt/apache-tomcat-8.5.35/temp/tomcat.pid

ExecStart=/opt/apache-tomcat-8.5.35/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```
The script tells the system to run the service as the tomcat user with the specified configs.

Reload Systemd in order to discover and load the new Tomcat service file:

systemctl daemon-reload
Enable the service to start at boot:

systemctl enable tomcat.service
To control the service:

service tomcat [start | stop | restart | status]
Or with Systemd directly:

systemctl [start | stop | restart | status] tomcat
