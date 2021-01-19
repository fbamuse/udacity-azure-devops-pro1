# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.


### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. Policy definition  
Define a tag-required policy in azure

2. Sign in with a service principal  
    >az login --service-principal -u <app-url> -p <password-or-cert> --tenant <tenant> 

3. create a server image included application  by Parcker   
Create an Ubuntu-based image with an embedded shell script that launches a static web service and register it as a custom image on Azure  
    >packer servier.json

4.  Infrastructure as code by terraform 
    - Initializes the working directory 
    >terraform init
    - View execution plan
    > terraform plan   
    - Create / edit / delete resources according to the tf file in the working directory 
    >terraform apply
    - The created resource will be deleted
    >terraform destroy 

    ![](picture/2021-01-18-21-20-48.png)  






## Detail 　
### tagging policy  
- Define a policy that requires tagging of resources. Predefined policies are displayed in 
    >az policy assingment list

    ![](picture/2021-01-16-19-47-34.png)
    ![](picture/2021-01-16-19-49-12.png)
If there is no tag, the resource will not be created.
    ![](picture/2021-01-16-22-55-38.png)


### Sign in with a service principal 
- Authenticate to Azure using the service principal
- A service principal is a security ID that you can use in your applications, services, and automation tools.
- Create a service principal with "az ad sp create-for-rbac" and output the credentials required by Packer.
![](picture/2021-01-16-20-14-44.png)
![](picture/2021-01-16-20-15-03.png)
- Input to parcker via environment variables.
![](picture/2021-01-16-20-19-20.png)

### packer run  
- Run Packer with the image template defined in Json as input.
![](picture/2021-01-16-20-20-13.png)
![](picture/2021-01-16-20-27-00.png)
The image was output to the specified resource group.
![](picture/2021-01-16-20-29-51.png)

### Infrastructure as code by terraform
#### var.tf  
- The following are variables
    - Number of VMs
    - Prefix to make the resource name unique. Also used for tag names
    - VM username and password
    - Service principal information

#### main.tf
- Multiple VMs with availability sets can be deployed in private subnet
- The virtual machine is generated from the prepared custom image.　　
- Virtual machines are load balanced by a public load balancer.　　
- Inbound does not allow communication except on port 80. (NSG)　　


#### Run
- init 
![](picture/2021-01-18-23-24-52.png)
- plan
![](picture/2021-01-18-23-23-53.png)
- apply
![](picture/2021-01-18-23-27-15.png)
![](picture/2021-01-18-23-28-02.png)
![](picture/2021-01-18-23-30-57.png)


### Output
- public loadbalancer
![](picture/2021-01-18-14-26-19.png)
- topology by network watcher
![](picture/2021-01-18-14-29-05.png) 
- all resource defiend by terraform 
![](picture/2021-01-16-21-37-01.png)
- All virtual machines are tagged with the project name.
![](picture/2021-01-18-23-33-49.png)

- The network security group explicitly denies inbound traffic from the internet except port 80 
![](picture/2021-01-18-23-32-52.png)

