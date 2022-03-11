This README.md page at https://github.com/wilsonmar/DevSecOps/blob/master/docker4aws/README.md
describes the repository https://github.com/wilsonmar/DevSecOps/master/docker4aws

This repository (docker4aws) contains files copied from the <a target="_blank" href="https://bootstrap-it.com/docker4aws/">https://bootstrap-it.com/docker4aws</a> web page created by David Clinton as part of his 12 June 2019 video class on Pluralsight <a target="_blank" href="https://app.pluralsight.com/library/courses/using-docker-aws/description">"Using Docker on AWS"</a>. The description for the class is:

> "Get yourself up to speed running your Docker workloads on AWS. Learn the CLI tools you'll need to manage containers using ECS - including Amazon's managed container launch type, Fargate - and Kubernetes (EKS) and the ECR image repo service."

The scripts here automate the creation of a WordPress image from DockerHub at <a target="_blank" href="https://hub.docker.com/_/wordpress/">https://hub.docker.com/_/wordpress/</a>

<img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">
Links to the specific video making use of the file is provided.
But know you need a subscription to Pluralsight to see the video.

There are two versions of the files: the original with hard-coded values, and 
one containing variables so you can reuse the files here for your own projects.

1. Add user

1. Create a public/private key.

1. Get into a new instance (subsituting the IP address) on Windows: <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=2&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">1:08</a>: 

   <pre>ssh -i newcluster.pem ubuntu@34.207.122.35</pre>

   On a Mac:

   <pre>ssh -i newcluster ubuntu@34.207.122.35</pre>


https://docs.docker.com/install/linux/docker-ce/ubuntu

### Script for installing Docker on Ubuntu

<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=2&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">1:43</a>:<br />
<pre>chmod +x install-docker.sh
./install-docker.sh</pre>

### A simple Dockerfile

1. Edit file <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=3&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">0:28</a>: 

   <pre>sudo nano /etc/group</pre>

1. Add line:

   <pre>docker:x:999:ubuntu</pre>

1. exit
1. Login again (substituting your IP address):

   <pre>ssh -i newcluster.pem ubuntu@34.207.122.35</pre>

1. Run (launch) a small Docker hello-world:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=3&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">1:41</a>: 

   <pre>docker run hello-world
   docker info
   </pre>
   
1. Get inside the image:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=3&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">2:11</a>: 

   <pre>docker run -it ubuntu bash
       # for> root@7f23d646e7d3:/#
   ls  # for> bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
   apt update
   exit</pre>

1. Back at local prompt:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=3&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">2:50</a>: 

   <pre>docker info
   docker ps
   docker rename goofy_mccarthy newname  # substitute
   docker inspect newname | less
   </pre>
   

1. Network:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=3&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">3:50</a>: 

   <pre>docker network ls
docker network create newnet
docker inspect newnet | less   # "Driver": "bridge", "Subnet": "172.18.0.0/16",  # substituted
docker network connect newnet newname  # no response if good.
docker inspect newname  # should show both addresses
ping 172.18.0.2  # substitute from "IPAddress": "172.18.0.2",
ping 172.17.0.2  # substitute from "IPAddress": "172.17.0.2",
   </pre>

1. Create or navigate to a folder "simple" and download the Dockerfile <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=4&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">0:10</a>

   <pre>
   cd simple  # in repo for Dockerfile inside
   curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/simple/Dockerfile
   </pre>

1. Instantiate a webserver:

   <pre>
DOCKER_SERVER_NAME="webserver"
DOCKER_SERVER_PORT="80"
docker build -t "$DOCKER_SERVER_NAME" .
docker images
# specify -p after -d :
docker run -d -p "$DOCKER_SERVER_PORT:80" "$DOCKER_SERVER_NAME" /usr/sbin/apache2ctl -D FOREGROUND
curl localhost  # RESPONSE="Welcome to my web site"
cd ..
   </pre>

### Build and run wordpress locally

1. Create wordpress with one command: <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=5c32300b-f24d-452b-80ac-36c6cf2985fd&clip=5&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">1:12</a>

   <pre>docker run -it wordpress /bin/bash  # for root@a2c20e10a430  substituted
   exit
   </pre>

1. Instatiate

<strong>docker-container-build.sh</strong>

### WordPress stack.yml file for local deployment

1. Instantiate wordpress and mysql 5.7 locally <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=440cc04e-14c6-45e5-ba8d-2df97c1b1358&clip=1&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">*</a>

   <pre>curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/stack.yml
   </pre>

   NOTE: The image of the stack.yml file on the video does not show the "---" on the first line which defines yml files.
   
   NOTE: Credentials inside yml files are insecure.

1. To avoid "this node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again"<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=440cc04e-14c6-45e5-ba8d-2df97c1b1358&clip=1&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">2:21</a>

   <pre>docker swarm init
   docker stack deploy -c stack.yml mywordpress
   </pre>

1. Get IP address for "en0" : http://192.168.1.16 for "Welcome to my website"

   <pre>ip a</pre>   


### ecs-cli-config.sh for EC2 launch type

1. Install AWS-CLI and ECS-CLI on your machine: <a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=440cc04e-14c6-45e5-ba8d-2df97c1b1358&clip=1&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">3:40</a>

   <a target="_blank" href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html">https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html</a>

   <pre>curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/ecs-cli-config.sh
   chmod +x ecs-cli-config.sh
   <strong>./ecs-cli-config.sh</strong></pre>

1. Define the configuration:

   <pre>curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/ecs-cli-config-ec2.sh
   chmod +x ecs-cli-config-ec2.sh
   <strong>./ecs-cli-config-ec2.sh</strong></pre>

   RESPONSE: "INFO[0000] Saved ECS CLI cluster configuration ec2-test-App."

1. Get an AWS account.

1. Get and edit file <strong>ecs-cli-config-profile.sh</strong> with your own AWS access key and secret key:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=440cc04e-14c6-45e5-ba8d-2df97c1b1358&clip=1&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">4:20</a>

   <pre>curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/ecs-cli-config-profile.sh
   nano ecs-cli-config-profile.sh
   </pre>

1. Get and edit file <strong>ecs-cli-config-profile.sh</strong> with your own AWS access key and secret key:<a target="_blank" href="https://app.pluralsight.com/player?course=using-docker-aws&author=david-clinton&name=440cc04e-14c6-45e5-ba8d-2df97c1b1358&clip=1&mode=live"><img width="20" height="20" src="https://wilsonmar.github.io/images/Video-icon-800x800.svg">4:20</a>

   <pre>curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/ecs-cli-compose.sh
   chmod +x ecs-cli-compose.sh
   ./ecs-cli-compose.sh
   </pre>


   curl -O https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/docker4aws/ecs-ec2-launch.yml
   <strong>ecs-ec2-launch.yml</strong>

### docker-compose.yml for EC2 launch

<strong>docker-compose.yml</strong>

### ecs-params.yml for EC2 launch

<strong>ecs-params.yml</strong>

### Launch EC2 type

<strong>ecs-ec2-launch.sh</strong>

### YAML files for Fargate

<strong>ecs-fargate-launch.yml</strong>

### Launch Fargate type

<strong>ecs-fargate-launch.sh</strong>

### Install eksctl, kubectl, and aws-iam-authenticator

<strong>install-ecs-utils.sh</strong>

### Build Kubernetes cluster and download YAML files

<strong>eksctl-create-cluster.sh</strong>

### Build Apache webserver container on Docker CE

<strong>Apache/Dockerfile</strong>

### Apache on ECS

<strong>Apache/docker-compose.yml</strong>

### ECR authentication and administration

<strong>ecr-auth-admin.sh</strong>
