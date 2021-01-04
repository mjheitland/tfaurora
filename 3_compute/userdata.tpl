#!/bin/bash
sudo echo "Host in ${subnet}" >> /var/log/mylog.txt

sudo yum update -y
sudo echo "yum updated" >> /var/log/mylog.txt

sudo amazon-linux-extras install postgresql11
sudo echo "postgres 10 installed" >> /var/log/mylog.txt
