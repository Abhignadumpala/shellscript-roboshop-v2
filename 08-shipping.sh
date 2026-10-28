#!/bin/bash

app_name=shipping
source ./common.sh
check_root

export MAVEN_OPTS="-Djdk.tls.namedGroups=x25519,secp256r1,secp384r1"    # FIX: X25519MLKEM768 keypair error in mvn

app_setup
java_setup

dnf install mysql -y &>> $logs_file
validate $? "Installing MySQL client"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file )
if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "Loading shipping data"
else
    echo -e "$(timestamp) [INFO] Master data already loaded...${Y}SKIPPING${N}"
fi

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "Creating APP user"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file

systemd_setup


restart
total_time
