#!/bin/bash
sudo echo "Host in ${subnet}" >> /var/log/mylog.txt

sudo yum update -y
sudo echo "yum updated" >> /var/log/mylog.txt

# March 2021: postgresql12 not yet available on Amazon Linux 2, so we still go with postgresql11
sudo amazon-linux-extras install postgresql11
sudo echo "postgresql11 installed" >> /var/log/mylog.txt
