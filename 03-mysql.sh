#!/bin/bash

source ./common.sh
check_root

dnf module enable mysql:8.4 -y &>> $logs_file
dnf install mysql-server -y &>> $logs_file
validate $? "installing mysql"

systemctl enable mysqld &>> $logs_file
systemctl start mysqld &>> $logs_file
validate $? "start and enable mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $logs_file
validate $? "setup MySQL root user and password"

total_time