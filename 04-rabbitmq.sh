#!/bin/bash

source ./common.sh
check_root

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "adding rabbitmq repo"

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "installing rabbitmq server"


systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "starting and enabling rabbitmq server"

rabbitmqctl list_users | grep -qw "roboshop"
if [ $? -ne 0 ]; then
     rabbitmqctl add_user roboshop roboshop123 &>> $logs_file
     validate $? "Creating RabbitMQ user for Roboshop" 
else
    echo -e "$(timestamp) [INFO] RabbitMQ user already exist...${Y}SKIPPING${N}" | tee -a $logs_file
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "Setting permissions for RabbitMQ user for Roboshop"


total_time