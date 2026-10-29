# RoboShop v2: Shell Scripts with Shared Functions

> Version 2 of [RoboShop v1](https://github.com/Abhignadumpala/shellscript-roboshop-v1). It deploys the same e-commerce app (frontend, 6 microservices, 4 databases) on **AWS EC2** with **Bash** and the **AWS CLI**. The difference: code every script needs lives **once** in [`common.sh`](common.sh), so each component script is short.

📖 **Notes, step-by-step lab guide and troubleshooting:** [devops-notes / Day 17](https://github.com/Abhignadumpala/devops-notes/tree/main/day-17-roboshop-v2-common-functions)

---

## v1 vs v2

| | v1 | v2 |
|---|---|---|
| Root check, logs, `validate`, colors | copied into every script | once in `common.sh` |
| Fix shared code | edit up to 10 files | edit 1 file |
| `05-catalogue.sh` | 91 lines | 29 lines |

Example: [`05-catalogue.sh`](05-catalogue.sh)
```bash
app_name=catalogue
source ./common.sh
check_root

app_setup
nodejs_setup
systemd_setup
```

## common.sh functions

| Function | Does |
|---|---|
| `check_root` | stop if not run as root |
| `validate` | print SUCCESS / FAILED, stop on failure |
| `app_setup` | create `roboshop` user, download app code into `/app` |
| `nodejs_setup` / `java_setup` / `python_setup` | install the runtime + app dependencies |
| `systemd_setup` | copy the `.service` file, enable + start the app |
| `restart` | restart the app |
| `total_time` | print how long the script took |

Every step is logged to `/var/log/roboshop/<script>.log`.

## How to run

**1. Laptop:** create the servers and DNS records.
```bash
bash roboshop.sh mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend
```

**2. Each server:** clone the repo and run that server's script.
```bash
ssh ec2-user@<public-ip>
sudo su -
git clone https://github.com/Abhignadumpala/shellscript-roboshop-v2.git
cd shellscript-roboshop-v2
bash 01-mongodb.sh
```

## Scripts

| Script | Server | Installs | Run time |
|---|---|---|---|
| [roboshop.sh](roboshop.sh) | laptop | EC2 instances + Route 53 records | – |
| [01-mongodb.sh](01-mongodb.sh) | mongodb | MongoDB | 105 s |
| [02-redis.sh](02-redis.sh) | redis | Redis 7 | – |
| [03-mysql.sh](03-mysql.sh) | mysql | MySQL 8.4 | 25 s |
| [04-rabbitmq.sh](04-rabbitmq.sh) | rabbitmq | RabbitMQ + app user | 181 s |
| [05-catalogue.sh](05-catalogue.sh) | catalogue | Node.js app + products | 58 s |
| [06-user.sh](06-user.sh) | user | Node.js app | 26 s |
| [07-cart.sh](07-cart.sh) | cart | Node.js app | 29 s |
| [08-shipping.sh](08-shipping.sh) | shipping | Java app + cities in MySQL | 33 s |
| [09-payment.sh](09-payment.sh) | payment | Python app | 94 s |
| [10-frontend.sh](10-frontend.sh) | frontend | Nginx reverse proxy | 94 s |

Support files: [mongo.repo](mongo.repo) · [rabbitmq.repo](rabbitmq.repo) · [catalogue.service](catalogue.service) · [user.service](user.service) · [cart.service](cart.service) · [shipping.service](shipping.service) · [payment.service](payment.service) · [roboshop.conf](roboshop.conf)

## Result

All 10 servers built with v2, all `/api/*/health` = 200, and an order placed end to end (register → cart → shipping → payment → order history).

## Tech stack

AWS EC2 (RHEL 9), Route 53, Security Groups · Bash, AWS CLI · Nginx · Node.js, Java + Maven, Python · MongoDB, Redis, MySQL, RabbitMQ · systemd
