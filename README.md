# Set Up for EC2 instance with NGINX web server running in a Docker container using Terraform 

## Overview:
Configuration in this directory will provision a t2.micro EC2 instance, VPC, Subnet, Internet gateway, custom route table, security group, network interface and AWS elastic IP.  Inside the EC2 instance, the script will install Ubuntu 18.04, Docker CE and python modules required for the REST API. Also it will create an NGINX  Docker container. Variables are declared in the variables.tf file and variables are defined in the dev.tfvars file.

## Usage
To run this you need to execute:
```
$ terraform init
$ terraform plan -var-file=dev.tfvars
$ terraform apply -var-file=dev.tfvars
```

**There are 9 total steps in the main.tf file**
## Steps:
Initial step is to configure the AWS provider. Credential to connect to the provider and the region is passed as input parameters. It is defined inside the dev.tfvars file.  The resource provisioning section start with provisioning a custom VPC. Followed by provisioning an internet gateway to  send traffic out to the internet. Then next step is to provision a custom route table. Technically this step is optional but I have added to make everything custom. In the next step we are provisioning a  custom subnet and in the follwed step the subnet is assigned to the route table. In the next step we are creating a custom security group to allow traffic from ports 22 for SSH, 80 for HTTP and 443 for HTTPS. Generally I should not enable port 22 and 80 but I did it for the purpose of development.  In the next step we are creating a custom network interface and it is assigned to the subnet we have created above.  Followed by provisioning an elastic IP and assign it to the network interface we have created above. Finally we are provisioning an Ubuntu server and we are assigning the network interface we have created above. In the user data section we are installing Docker and few python modules required for the REST API.  Also I have enabled the firewalld for the Ubuntu server to have better control over the security. In the current set up i have't disabled HTTP and SSH. But if required we can modify the firewalld settings and disable it. And inside the provisioner block we are transferring the scripts for log monitoring and REST API  to the remote server.

Coming to the healthcheck.sh monitoring scrpit, it is a basic shell scrpit to write the docker stats and ps commands output to a log file resource.log. Script collects the metrics every 10s. The log file contains following values.  
```
Datestamp
ContainerI
Name
Image
Status
CpuPercentage
MemoryPercentage
MemoryLimit
NetIO
```

The REST API is written in python using Flask module. Also I have used pandas to validate the data. In the GET API, we are passing datestam or name. It will gives the corresponding output. Since we have only one container using container name is irrelevant in this case. 

## ENV Screenshots:
Ubuntu OS:

<img width="289" alt="Screenshot 2021-08-09 at 10 15 33 PM" src="https://user-images.githubusercontent.com/87153853/128691737-cf9a0d26-213f-4619-a1d9-b430ea981650.png">
NGINX Container:

<img width="956" alt="Screenshot 2021-08-09 at 10 17 36 PM" src="https://user-images.githubusercontent.com/87153853/128691891-5542d58c-b61b-4114-a1e0-63093d436f52.png">

Firewalld:

<img width="511" alt="Screenshot 2021-08-09 at 9 23 47 PM" src="https://user-images.githubusercontent.com/87153853/128692039-80e2ebd0-b8e8-4d72-a46c-587435f5c53a.png">

Resource.log

<img width="739" alt="Screenshot 2021-08-09 at 10 23 35 PM" src="https://user-images.githubusercontent.com/87153853/128692565-6c59dac7-70c5-4fc7-a0d2-0bb57017ab23.png">









## Sample output for the log search using REST API:
```
curl http://127.0.0.1:5000/search?key=datestamp&value=20210809
```
<img width="849" alt="Screenshot 2021-08-09 at 9 52 47 PM" src="https://user-images.githubusercontent.com/87153853/128691278-b5840dd1-b42b-484d-9c30-4224c06628ec.png">


## Risks:
The major risk for the current set up is exposed port 22 and port 80 to the public. In general we should only allow 443. 
I am using the IAM access key for authentication. For best practice we should rotate the IAM access keys at least every 90 days. 
I am using a broad IP range here. Best practice is not to use a broad IP ranges for smaller deployments.

## Bonus Point question:
I haven't implemented it in the code. But I do have the solution overview available. It can be done by writing the API in Flask (which we already did) and use Gunicorn as the app server and configure it to NGINX webserver. We can do this by creating docker image with flask py and gunicorn and create another docker image with the custom nginx.conf file and settings required for site-avaiable for NGINX. Combine both Dockerfiles with docker-compose. 
