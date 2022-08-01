# AWS CICD

### install environment to create Docker file

In the VM install the following:

- install python 3.8,3.9 or 3.10
- Install Apache and mod_wsgi for Production
- install databindings
```
If you’re using PostgreSQL, you’ll need the psycopg2 package. Refer to the PostgreSQL notes for further details.
If you’re using MySQL or MariaDB, you’ll need a DB API driver like mysqlclient. See notes for the MySQL backend for details.
If you’re using SQLite you might want to read the SQLite backend notes.
If you’re using Oracle, you’ll need a copy of cx_Oracle, but please read the notes for the Oracle backend for details regarding supported versions of both Oracle and cx_Oracle.
If you’re using an unofficial 3rd party backend, please consult the documentation provided for any additional requirements.
```

Install Detail:

```
sudo apt upgrade
sudo apt update
sudo apt install -y xz-utils
sudo apt install -y build-essential
sudo apt install -y libssl-dev
sudo apt install -y libsqlite3-dev
sudo apt install -y zlib1g-dev
sudo apt install -y libffi-dev
mkdir ~/python_src
cd ~/python_src
wget https://www.python.org/ftp/python/3.9.9/Python-3.9.9.tar.xz
tar xf Python-3.9.9.tar.xz 
cd Python-3.9.9
./configure --enable-shared --prefix=/home/wsgi/Python-3.9.9 --with-ensurepip=install --enable-optimizations
make
make install

vim ~/.bashrc
export PATH=/home/wsgi/Python-3.9.9/bin:$PATH
export LD_LIBRARY_PATH=/home/wsgi/Python-3.9.9/lib
export LD_RUN_PATH=/home/wsgi/Python-3.9.9/lib
```
Install Docker

CLICK [[HERE](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04-es)] TO ACCESS TUTORIAL

Give permisions to the user to access docker:
```
sudo usermod -aG docker ${USER}
```

logout and login to perform changes


Clone the repository to your local machine.
```
git clone https://github.com/jordy33/django-markdown-editor.git
```

- First, create a Python virtual environment:
```
cd django-markdown-editor/
echo venv/ >> .gitignore
echo martor >> requirements.txt
echo gunicorn >> requirements.txt
pip install -r requirements.txt
```
- And start the development server, you can visit your application at http://127.0.0.1:8000:
```
cd martor_demo
python manage.py runserver 0.0.0.0:8000
```

You have 18 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
Run to migrate:
```
python manage.py migrate
```

- create an AWS instance. Open port 80, assign static ip
- install Docker in the machine

Pulling an image from docker hub
```
docker pull ubuntu:20.04
docker image ls -a
```
run the container (inject terminal)
```
docker run -it -p 80:80 <image ID>
```
Inside of the container
```
apt-get update && apt-get install -y python3.9 python3.9-dev
exit 
docker ps -a
docker commit 8c573f9778a0 python39
docker images
```

Create Docker File:
vim Dockerfile
```
FROM ubuntu:20.04
MAINTAINER JorgeMacias
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="America/Mexico_City"
RUN apt update
RUN apt -y install tzdata
RUN ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime
RUN apt --no-install-recommends -y install python3.9
RUN apt -y install python3.9-venv
RUN apt -y install git
RUN cd /home
RUN git clone https://github.com/jordy33/django-markdown-editor.git
RUN cd django-markdown-editor
RUN echo martor >> requirements.txt
RUN echo gunicorn >> requirements.txt
RUN python3.9 -m venv venv
RUN /home/django-markdown-editor/venv/bin/pip install -r /home/django-markdown-editor/requirements.txt
RUN cd martor_demo
EXPOSE 8000
RUN /home/django-markdown-editor/venv/bin/python3.9 manage.py  runserver 0.0.0.0:8000
```

Build Image
```
docker build -t webserver .
```
List images
```
docker images
```
Result
```
operations@ip-172-31-22-38:~/Docker/sun-docker-repo$ 
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
webserver    latest    e4308442e98d   6 seconds ago   340MB
ubuntu       20.04     20fffa419e3a   7 weeks ago     72.8MB
```

Run image in the background
```
docker run -itd -p 8000:8000 
```
Result. 
```
wsgi@ip-172-31-22-38:~/Docker$ docker image ls
REPOSITORY    TAG       IMAGE ID       CREATED         SIZE
webserver     latest    357bbac81f06   10 days ago     340MB
ubuntu        20.04     20fffa419e3a   6 weeks ago     72.8MB
hello-world   latest    feb5d9fea6a5   10 months ago   13.3kB
```
Open the website at port 8000. If ok, the Dockerfile i ok.

### Creating CI/CD in AWS

Login to ECR
```
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 998441165748.dkr.ecr.us-east-2.amazonaws.com
```
Tag the repository to ECR
```
docker tag webserver:latest 998441165748.dkr.ecr.us-east-2.amazonaws.com/madd:latest
```

Pushing local image to the ECR
```
docker push 998441165748.dkr.ecr.us-east-2.amazonaws.com/madd:latest
```
The push refers to repository [998441165748.dkr.ecr.us-east-2.amazonaws.com/madd]
```
30b4bbe488b2: Pushed 
42d070317948: Pushed 
57b32de5a93b: Pushed 
d513e5b89c2f: Pushed 
399924774f31: Pushed 
76920902b2b7: Pushed 
1c3b2b229dec: Pushed 
400de0013773: Pushed 
f7897f3f135b: Pushed 
ed3a84c2e0a3: Pushed 
2bfeb9563b43: Pushed 
af7ed92504ae: Pushed 
latest: digest: sha256:3a53273c6cd5cfb8c4f234302c8efaeb960ad76858a846315878602688e934d7 size: 2844
```

To this point is hosted in AWS ECR

Now we are going to ECS Elastic Container Service and configure the following:
```
- Task Definitions
Click Create task definitions
Select Fargate
Taks Name: cicd-task
Task size: .5 Gb
Task CPU: .25 CPU
Add Cointainer 
 - container name : web1
 - image: put inage uri from ECR
 - put port 80

click add 
click create task

Task definition status - 3 of 3 completed
Create Execution Role
Execution Role AmazonECSTaskExecutionRole created Learn more
Create Task Definition: cicd-task
cicd-task succeeded
Create CloudWatch Log Group
CloudWatch Log Group created
CloudWatch Log Group /ecs/cicd-task
```

Go To Cluster and Create a Cluster
```
For the Fargate (Networking only)
Click Next
Configure Cluster
Clouster name: cicd-cluster
(no services no task nothing)

click on create to create a service
launch type : Fargate
son Service name type: service1
In number of tasks put : 2
Select Rolling update
-
Select Cluster VPC (same as machine desarrollo)
Select all the subnets (a b c)
Select Application Load Balancer (create one load balancer from EC2, http https. Shceme :internet-facing, select vp and zones, selecty target group name :tg1, type;instance, port:80)
Health threshold:
Click add to load Balancer:
web1: 80
Production listener port :80 HTTP
patern put: /*
Evaluation order: 1
Health check path /
Enable DNS integration
Activate auto Scaling
click create service
```

Go to the load balancer and add the service security group

Until now we ve created de ECS part

### Configuring: CODE COMMIT 

Create code commit
```
-  Look in AWS code commit (alternate for git hub,bitbucket)
   - click Create new repository
     Repository Name: docker-repo
   - install git in the VM that have 
   - go to iam , click users, create user or select user, select security credentials tab,HTTPS Git credentials for AWS CodeCommit
```

go to the VM
```
cd Docker
git clone https://git-codecommit.us-east-2.amazonaws.com/v1/repos/sun-docker-repo
```
Enter the credentials:
```
user: jorge@************
password: ****************************
```

Alternate method via ssh
```
ssh-keygen
will Generate: id_rsa and id_rsa.pub
cat id_rsa.pub
go to SSH keys for AWS CodeCommit
click upload ssh public key
copy ssh key id: APKA6Q553EO2PG6FNL62

cd .ssh
vim config
```
Insert the following:
```
Host git-codecommit.*.amazonaws.com
User APKA6Q553EO2PG6FNL61
IdentityFile ~/.ssh/id_rsa
```
Change permisions
```
chmod 600 config
```
Do a commit
```
cd ~/Docker/sun-docker-rep
git add .
only one branch
On branch master
git commit -am"first commit"
```

Check the repository and the files must be there

### Configuring: CODE BUILD

Code commit it will automatically take the source file and build a docker image in the code
```
click BUILD
  - click Getting started
     - click create project
       project name: docker-build
       source: AWS CodeCommit
       repository : sun-docker-repo
       branch: master
       Operative system : Ubuntu
       Run time: Standard
       image aws/codebuid/standard:4.0
       Privileged
       CHECK Enable this flag if you want to build Docker images or want your builds to get elevated privileges
       Service role: New service Role
      - Configuration for the VPC
        Certificate: click do not install certificate or install certificate for your s3 bucket
        VPC : Do no select

       - Build Spec:
         - use a Build spec file        
       - Artifacts: No artifacts (the first time) "very important for the ci cd pipeline"

  - Click: Create build project
```
Once created if you build is going to fail because we dont have a build spec file
[Container] 2022/07/26 18:26:26 Phase context status code: YAML_FILE_ERROR Message: YAML file does not exist
Go to the terminal and create a buildspec file:

### Configuring: CODE DEPLOY
will take the code commit and will build a docker image in the code
```
cd ~/Docker/sun-docker-rep
vim buildspec.yaml
```
Paste the following:
```
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - $(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t  web:1 .
      - docker tag web:1 998441165748.dkr.ecr.us-east-2.amazonaws.com/madd
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push 998441165748.dkr.ecr.us-east-2.amazonaws.com/madd
```

The docker tag and push has the uri obtained from the AWS ECR

Update the repository:
```
git add .
git commit -am" yaml added"
git push
```
**** ERROR when building ** say that you dont have permision to contact the ECR

Go to the iam
and find the code build role and allow the ecr access over there.
go to:
```
   - IAM
   - roles search : codebuild-docker-build-service-role
   - click on the role
   - click add permisions then attached poicy
   - find container
   - select AmazonEC2ContainerRegistryFullAccess
   - click attach policies
```
Get back to the codebuild and retry
success 

Using default tag: latest
The push refers to repository [998441165748.dkr.ecr.us-east-2.amazonaws.com/madd]

Go to the ECR
and find that a new cointainer is created


### Creating: CODE PIPELINE 

Every time that a commit in the git hub will create a new image in the repository of the ECR
and then to the elastic cointainer service ECS
```
Check codecommit
Build the image
then go to the ECS - task definitions
select the task
and click create new revision
  - TaskRole: ecsTaskExecutionRole 
  - change the container, go to the ecr copy the image tag
  - and then update the service
```

The in ECS will be task one running and task2 provisioning
then all the 4 task are running

Automating the process with codepipeline 

```
go to CodeCommit - Pipeline - Getting started
 - Click Create a pipe - line
   Pipeline name: ECS-pipeline
    -  go to advance setting
       artifact Store: select default location
       (that will create a s3 bucket for you)
    - click next 
    - Source
          Source provider: AWS CodeCommit
          Repository name: sun-docker-repo
          branch name: master
          detection options: Amazon Cloudwatch Events
    - click next
    - Add Build stage
          Build Provider: AWS Codebuild
          Region US Est (n. virginia)
          project name: docker-build
    - click next
    Deploy stage 
          provider: Amazon ECS
          region : US East ohio
          cluster name: cicd-cluster
          service name: service1
          image definition file : later will be
    - Click create pipe line
          Congratulations! The pipeline ECS-pipeline has been created.
```
We are going to get an error on Deploy section 
click in the error Pipeline execution Id

Latest action execution message
Unable to access the artifact with Amazon S3 object key 'ECS-pipeline/BuildArtif/HTrbVK9' located in the Amazon S3 artifact bucket 'codepipeline-us-east-2-887897223734'. The provided role does not have sufficient permissions.
```
to FIX go to:
  Iam
  - go to the roles:
    search : codepipeline
    select (click in the role): AWSCodePipelineServiceRole-us-east-2-ECS-pipeline
    go to the attach policies: 
    - search s3
      and select: AmazonS3FullAccess
    - click : attach policies

- Get back to the code Pipeline :
    - Click on retry deploy (will mark error)

Go to Codepipeline
   - Select Build
      - Build Projects
        - Docker build (click Edit)
           - Select Artifacts
              - Select Amazon S3
                and select the bucket: codepipeline-us-east-2-887897223734
                Name: output
                Path: /
                Namespace type: None
                Artifacts packaging: zip
                - click update the artifacts

Go to Codepipeline
     - Select pipeline 
        - Select ECS in the deploy section:
           - Click Edit stage:
               - click in the write page icon
                  select input artifacts as: Source artifacts instead build artifacts
                  image definitions file put : imagedefinitions.json
                   - click : done
                    - click : save
              
```
go to terminal:
```
vim imagedefinitions.json
```
put the following:
```    
[
    {
        "name": "web1",
        "imageUri": "998441165748.dkr.ecr.us-east-2.amazonaws.com/madd:latest"
    }
]
```

### Configuring secure access

- Go to the balancer and get dns name
- go to Aws53 create a cname record with the FQDN pointing to the load balancer dns name
- go to AWS Certificate Manager

Request a public certificate, for the FQDN (step above). Create in route 53 the cname key pairs that aws is requiring to enable the certificate. 
Validate that the certificate is created.

- Go to the load balancer and create a listener. (https)


To modify the health check settings of a target group using the console

Open the Amazon EC2 console at https://console.aws.amazon.com/ec2/.
On the navigation pane, under LOAD BALANCING, choose Target Groups. Select the target group.
On the Health checks tab, choose Edit.
On the Edit target group page, modify the setting Success Codes to 302 or as needed, and then choose Save.

If you need to clean all images:
```
docker rm -f $(docker ps -qa)
docker rmi -f $(docker images -aq)
```


