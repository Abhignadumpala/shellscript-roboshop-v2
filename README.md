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

## Do the lab yourself (step by step)

```
                  ┌──────────► catalogue ──► mongodb
browser ──► frontend (Nginx) ─► user ──────► mongodb, redis
                  ├──────────► cart ───────► redis
                  ├──────────► shipping ───► mysql
                  └──────────► payment ────► rabbitmq
```

### Step 0: What you need

| Need | Why |
|---|---|
| AWS account + **AWS CLI** configured on your laptop (`aws configure`) | `roboshop.sh` creates servers from the laptop |
| A **domain** with a **Route 53 hosted zone** | every server gets a name like `mongodb.<your-domain>` |
| A **RHEL 9** AMI | all scripts use `dnf` + systemd |
| Git on the laptop | clone / fork this repo |

`roboshop.sh` doesn't attach a key pair (I used a practice AMI with password login). With a normal RHEL AMI, add `--key-name <your-key>` to `aws ec2 run-instances` and SSH with `-i <your-key>.pem`.

### Step 1: Fork and set your values

Fork this repo, clone it to your laptop, and change these 4 values to yours:

| File | Variable | Set to |
|---|---|---|
| `roboshop.sh` | `ami_id` | your RHEL 9 AMI ID |
| `roboshop.sh` | `hosted_zone_id` | your Route 53 hosted zone ID |
| `roboshop.sh` | `domain_name` | your domain |
| `common.sh` | `domain_name` | your domain (same as above) |

The `.service` files and `roboshop.conf` use `DOMAIN_NAME`; the scripts replace it with your domain on the server, so you don't edit those.

Push your changes (servers clone from **your** fork):
```bash
git add roboshop.sh common.sh
git commit -m "Set my AMI, hosted zone and domain"
git push
```

### Step 2: Create the security groups (once)

`roboshop.sh` attaches 2 SGs to each server: `roboshop-common` + `roboshop-<component>`. Create these in the default VPC:

| Security group | Inbound port | Allowed from |
|---|---|---|
| `roboshop-common` | 22 (SSH) | your IP |
| `roboshop-frontend` | 80 | `0.0.0.0/0` (everyone) |
| `roboshop-catalogue` | 8080 | frontend, cart |
| `roboshop-user` | 8080 | frontend, payment |
| `roboshop-cart` | 8080 | frontend, shipping, payment |
| `roboshop-shipping` | 8080 | frontend |
| `roboshop-payment` | 8080 | frontend |
| `roboshop-mongodb` | 27017 | catalogue, user |
| `roboshop-redis` | 6379 | user, cart |
| `roboshop-mysql` | 3306 | shipping |
| `roboshop-rabbitmq` | 5672 | payment |

"Allowed from frontend" = source is the SG `roboshop-frontend`, not an IP, so the rule still works when servers get new IPs.

### Step 3: Create the servers (laptop)

```bash
bash roboshop.sh mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend
```

For each name it creates the EC2 server `roboshop-<name>` and a DNS record:

| Server | DNS record | IP used |
|---|---|---|
| frontend | `<your-domain>` | **public** (for the browser) |
| all others | `<name>.<your-domain>` | **private** (server to server) |

### Step 4: Install each component (on each server)

SSH into each server, clone **your** fork and run that server's script:
```bash
ssh ec2-user@<public-ip>
sudo su -
git clone https://github.com/<your-username>/shellscript-roboshop-v2.git
cd shellscript-roboshop-v2
bash 01-mongodb.sh            # the script for this server (table below)
```

Order matters: **databases first, then apps, frontend last.**

| Order | Server | Run |
|---|---|---|
| 1 | roboshop-mongodb | `bash 01-mongodb.sh` |
| 2 | roboshop-redis | `bash 02-redis.sh` |
| 3 | roboshop-mysql | `bash 03-mysql.sh` |
| 4 | roboshop-rabbitmq | `bash 04-rabbitmq.sh` |
| 5 | roboshop-catalogue | `bash 05-catalogue.sh` |
| 6 | roboshop-user | `bash 06-user.sh` |
| 7 | roboshop-cart | `bash 07-cart.sh` |
| 8 | roboshop-shipping | `bash 08-shipping.sh` |
| 9 | roboshop-payment | `bash 09-payment.sh` |
| 10 | roboshop-frontend | `bash 10-frontend.sh` |

Each step prints **SUCCESS** or **FAILED**. On FAILED the script stops; read `/var/log/roboshop/<script>.log`.

### Step 5: Check it works

On the frontend server:
```bash
curl localhost/api/catalogue/health
curl localhost/api/user/health
curl localhost/api/cart/health
curl localhost/api/shipping/health
curl localhost/api/payment/health
```
All should answer with `OK` / `UP`.

### Step 6: Open the shop in the browser

1. Go to `http://<your-domain>`.
2. **Register** a new user and log in.
3. Add a product to the cart.
4. Checkout → choose country and city for shipping.
5. Pay → open **Order history**: your order is there ✅.

### Step 7: Clean up

Terminate all 10 servers so you don't pay for them (EC2 → select → Terminate, or `aws ec2 terminate-instances --instance-ids <ids>`). The SGs and hosted zone can stay for the next run.

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
