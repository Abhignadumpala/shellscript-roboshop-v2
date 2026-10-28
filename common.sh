#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
scripts_dir=$(dirname "$(realpath "$0")")
domain_name="abhignadevops.store"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

check_root(){
    if [ $user_id -ne 0 ]; then
        echo "Please run this script with sudo access.."
        exit 1
    fi
}

timestamp(){
    date "+%F %T" 
}

mkdir -p $logs_folder

echo -e "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

total_time(){
    echo -e "$(timestamp) [INFO] Script completed in $SECONDS seconds" | tee -a $logs_file
    echo -e "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file    
}