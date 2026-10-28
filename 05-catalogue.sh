#!/bin/bash

app_name=catalogue
source ./common.sh
check_root

app_setup
nodejs_setup
systemd_setup



cp $scripts_dir/mongo.repo /etc/yum.repos.d/mongo.repo    # NEW: MongoDB client + load products
validate $? "adding mongo repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "installing mongodb client"

product_count=$(mongosh --host mongodb.$domain_name --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2>> $logs_file)    # NEW: load products only once
validate $? "connecting to mongodb"

if [ "$product_count" -eq 0 ]; then
    mongosh --host mongodb.$domain_name </app/db/master-data.js &>> $logs_file
    validate $? "loading catalogue products"
else
    echo -e "$(timestamp) [INFO] products are already loaded...${Y}SKIPPING${N}" | tee -a $logs_file
fi

restart
total_time