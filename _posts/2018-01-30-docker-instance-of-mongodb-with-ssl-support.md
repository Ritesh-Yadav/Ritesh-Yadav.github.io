---
title:  "Create Docker Instance of MongoDB with SSL Support"
categories: 
  - Tech
tags:
  - SSL
  - Letsencrypt
  - Openssl
  - Localhost
  - MongoDB
  - Docker
---

There are instances when you want to create MongoDB instance in Docker to use in production or in local/internal. We came across this requirement where we were using [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) for production but wanted to use [MongoDB docker](https://hub.docker.com/_/mongo/) in our local/internal/dev environment. Mongo Atlas uses SSL connection so we want to keep our local consistent with production environment. In this post, I am going to explain the process of creating Mongo Docker instance with valid SSL certificate and replicating same behavior of MongoDB Atlas.

Note: You can use same process for your production MongoDB instance as well, if you are not using any cloud solution for MongoDB
{: .notice}

All the code related to this post (except certificates) is available in [GitHub Repo](https://github.com/Ritesh-Yadav/mongodb-docker) for your reference.
{: .notice--info}

{% include base_path %}

{% include toc title="Index" %}

## Prerequisites

**Step 1.** SSL Certificates

If you don't have valid SSL certificate (**not self-signed**) issued by Certificate Authority please read and follow [Getting Valid SSL Certificate from Let's Encrypt for LocalHost]({{ "/tech/getting-valid-ssl-certificate-for-localhost-from-letsencrypt/" | absolute_url }}) else skip this step.
{: #pr_step1 .notice--info}

**Step 2.** [Docker](https://docs.docker.com/install/)

## Creating Required Files

**Step 1.** Create a project folder and inside that project folder create `scripts` and `ssl` folder. `scripts` folder will contain script to create user in MongoDB and start it. `ssl` will contain SSL certificate e.g. CA Root and certificate for MongoDB.

**Step 2.** Copy CA Root certificate and MongoDB certificate in `ssl` folder.

```bash
$ ls
ca.pem      mongodb.pem
```

**Step 3.** Create a `Dockerfile` as following in your project root folder. We are going to use official MongoDB docker container from [docker hub](https://hub.docker.com/_/mongo/).

```docker
FROM mongo:3.6.2-jessie

COPY scripts /home/mongodb/scripts

COPY ssl /home/mongodb/ssl

COPY mongod.conf /home/mongodb

WORKDIR /home/mongodb

RUN ["chmod", "+x", "/home/mongodb/scripts/"]

CMD ["/home/mongodb/scripts/run.sh"]
```

Note: In `mongo:3.6.2-jessie`, 3.6.2-jessie is tag which I am using. If you want to use latest Mongo container than remove `:3.6.2-jessie`
{: .notice}

**Step 4.** Create `mongod.conf` file in the same root folder.

```yaml
net:
  bindIp: 0.0.0.0
  port: 27017
  ssl:
    CAFile: /home/mongodb/ssl/ca.pem
    PEMKeyFile: /home/mongodb/ssl/mongodb.pem
    mode: requireSSL
    disabledProtocols: "TLS1_0,TLS1_1"
    allowConnectionsWithoutCertificates: true
storage:
  journal:
    enabled: true
```

**Step 5.** Now, Go to `scripts` folder and create `run.sh` and `setup_user.sh` files

`Content of run.sh:`

```bash
#!/bin/bash

sleep 5

chown -R mongodb:mongodb /home/mongodb

nohup gosu mongodb mongod --dbpath=/data/db &

nohup gosu mongodb mongo admin --eval "help" > /dev/null 2>&1
RET=$?

while [[ "$RET" -ne 0 ]]; do
  echo "Waiting for MongoDB to start..."
  mongo admin --eval "help" > /dev/null 2>&1
  RET=$?
  sleep 2
done

bash /home/mongodb/scripts/setup_user.sh

gosu mongodb mongod --dbpath=/data/db --config mongod.conf --bind_ip_all --auth
```

`Content of setup_user.sh:`
{: #setup_user}

```bash
#!/bin/bash

echo "************************************************************"
echo "Setting up users..."
echo "************************************************************"

# create root user
nohup gosu mongodb mongo DBNAME --eval "db.createUser({user: 'admin', pwd: 'YOUR_PASSWORD', roles:[{ role: 'root', db: 'DBNAME' }, { role: 'read', db: 'local' }]});"

# create app user/database
nohup gosu mongodb mongo DBNAME --eval "db.createUser({ user: 'myuser', pwd: 'YOUR_PASSWORD', roles: [{ role: 'readWrite', db: 'DBNAME' }, { role: 'read', db: 'local' }]});"

echo "************************************************************"
echo "Shutting down"
echo "************************************************************"
nohup gosu mongodb mongo admin --eval "db.shutdownServer();"
```

Pro Tip: You can create variables for commonly used commands in the file.
 {: .notice--info}

## Creating Docker Instance

**Step 1.** Go to project root folder which contains `Dockerfile` and run it to create docker image

```bash
$ docker build -t mongo .

Sending build context to Docker daemon  24.58kB
Step 1/7 : FROM mongo:3.6.2-jessie
 ---> 0f57644645eb
Step 2/7 : COPY scripts /home/mongodb/scripts
 ---> 8041e28c2137
Step 3/7 : COPY ssl /home/mongodb/ssl
 ---> ac293a519709
Step 4/7 : COPY mongod.conf /home/mongodb
 ---> ec399118fc0e
Step 5/7 : WORKDIR /home/mongodb
Removing intermediate container 6749cb04ff21
 ---> 0a5a5e3d4911
Step 6/7 : RUN ["chmod", "+x", "/home/mongodb/scripts/"]
 ---> Running in 64e50080f584
Removing intermediate container 64e50080f584
 ---> ce679220fcea
Step 7/7 : CMD ["/home/mongodb/scripts/run.sh"]
 ---> Running in 5044246929c9
Removing intermediate container 5044246929c9
 ---> dee2ad41b921
Successfully built dee2ad41b921
Successfully tagged mongo:latest
```

* `mongo:latest` is the tag name which we are going to use in next step.

**Step 2.** Now, run Docker image to create a container.

```bash
$ docker run -d -p 27017:27017 --mount source=mongodb,target=/data/db --mount source=configdb,target=/data/configdb --name mymongo mongo:latest
937a234022eb718edfbffec1d4dd35e31b5eb23e78f08776312f81b63535f848
```

* `937a234022eb718edfbffec1d4dd35e31....` is container ID created by command.
* `mongodb` and `configdb` are volumes to keep data on your local so that when you destroy your container you will still have your data. If you don't want to keep data of previous container, remove `--mount` option and it's arguments.
* `mymongo` is name of your container which you can use to run any command in that container.

**Step 3.** You can check logs of the container by `docker logs -f <CONTAINER ID OR NAME>`

```bash
docker logs -f mymongo
```

**Step 4.** Create an entry in your `/etc/hosts` file for the domain name which you have used to obtain your certificate. [see this]({{ "/tech/getting-valid-ssl-certificate-for-localhost-from-letsencrypt/#hostentry" | absolute_url }})

```bash
127.0.0.1           localhost ry-dev.herokuapp.com
```

* `ry-dev.herokuapp.com` is the domain name I used to get my SSL certificate.

**Step 5.** Now, you can try connecting to your MongoDB instance in docker

```bash
mongo --ssl --host ry-dev.herokuapp.com --port 27017 --username <USERNAME> --password <PASSWORD> --authenticationDatabase <DBNAME>
```

* Replace value of `<USERNAME>`, `<PASSWORD>` and `<DBNAME>` with the values which you have used in [setup_user.sh](#setup_user) file.
* You should not see any error related to certificate validation and should be connected to MongoDB successfully.
* You should not need to use command `--sslAllowInvalidCertificates` option from command line to connect to your MongoDB. If you do get error, please check you have [correct CA Root certificate and application certificate]({{ "/tech/getting-valid-ssl-certificate-for-localhost-from-letsencrypt/#verifycert" | absolute_url }}).

## Useful Docker Commands

* Check status of your container by `docker ps -a`
* Check logs of the container by `docker logs -f <CONTAINER ID OR NAME>`
* Remove any container `docker rm <CONTAINER ID OR NAME>`
* Get shell in container `docker exec -it <CONTAINER ID OR NAME> bash`