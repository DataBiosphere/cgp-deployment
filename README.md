# cgp-deployment (Commons Edition)

## About

This repository contains our Docker-compose and setup bootstrap scripts used to create a deployment of the [UCSC Genomic Institute's](http://ucsc-cgl.org)
Computational Genomics Platform for AWS. It uses, supports, and drives development of several key GA4GH APIs and open source projects.
In many ways it is the generalization of the [PCAWG](https://dcc.icgc.org/pcawg) cloud infrastructure developed for that project and a potential reference implementation for the [NIH Commons](https://datascience.nih.gov/commons) concept.

## Components

The system has components fulfilling a range of functions, all of which are open source and can be used independently or together.

These components are setup with the install process available in this repository:

* [Boardwalk](boardwalk/README.md): our file browsing portal on top of the Blue Box

These are related projects that are either already setup and available for use on the web or are used by components above:

* [Dockstore](https://dockstore.org): our workflow and tool sharing platform
* [Toil](https://github.com/BD2KGenomics/toil): our workflow engine, these workflows are shared via Dockstore

## Setting up the Enviroment

These directions below assume you are using AWS.  We will include additional cloud instructions as `cgp-deployment` matures.
    
### 1. Create the VM using the AWS Console
First, we need to setup an EC2 instance to install our server. You will need to use the AWS console or command
line tool to create a host. We will refer to this as the host VM throughout the rest of the documentation. 
It will run the Docker containers for all of the components listed below.

9. Select the region in AWS Console top toolbar. **Note** We have had problems when uploading big files to Virginia (~25GB).
    If possible, set up your AWS anywhere else but Virginia. Preferrably US-West-2 (Oregon).
9. In the AWS Web Console Top toolbar, Click on the **Services** > **EC2** (Under the **Compute** submenu)
    - **Note**:  Know which region to using in AWS. **Note** We have had problems when uploading big files to Virginia (~25GB).
    If possible, set up your AWS anywhere else but Virginia. Preferrably US-West-2 (Oregon)
9. In the sidebar, look under the **Instances** subsection, click the **Instances** link
9. Near to top of the page, click on the blue button with the name *Launch Instance*.
This should take you to the "Choose an Amazon Machine Image (AMI)" page.
9. Click on the **AWS Marketplace** Item in sidebar.
Then, search for **Ubuntu 16.04 Xenial**. This is the OS name of the Host VM, we will create.
9. Select an instance type for Host VM. We recommend the r4.xlarge instance.
If that instance is not available, an instance with similar specs will do. When you're done, click **Next: Configure Instance Details**"
9. In the Configure Instance Details step, leave everything as is and click next to **Next: Add Storage**.
9. In the Add Storage Step, set the **size** of the **root** volume to **250** GB. Then, click **Next: Add Tags**.
9. In the Add Tags step, Create all the tags in the following table. 
   
   |Name|Value|
   |-----|----|
   |Owner|Your Email Address|
   |Name| The Name of your VM Host|
   
   Once all the tags are added, click **Next: Configure Security Group**.
  
9. In the security group step, have the inbound settings from the following table. Then, confirm.

    |Type|Protocol|Port Range|Source|
    |----|--------|----------|------|
    |SSH|TCP|22|0.0.0.0/0|
    |SSH|TCP|22|::/0|
    |HTTP|TCP|80|0.0.0.0/0|
    |HTTP|TCP|80|::/0|
    |HTTPS|TCP|443|0.0.0.0/0|
    |HTTPS|TCP|443|::/0|
    
    Finally, click **Review and Launch**.
9. You should be in the Review Instance Launch page. Check your configurations and click **Launch** to launch the Host VM.
9. A popup should appear asking you to create your SSH Key Pair. 
Create a new key pair with a unique name and click on **Download Key Pair** to download it to a CSV file. 
After confirming your key pairs, the Host VM should be created.

### 2. Generating Elastic IP
Next, we need to set an Elastic IP for our Host VM. Elastic IPs are just static IPs designed for dynamic cloud computing.

9. Install/Upgrade AWS CLI to the latest version. If you need help installing the AWS CLI,
please click [here](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
9. If you don't know your AWS Access keys and Secret Keys, please go [here](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) to setup them up.
Otherwise, skip to the next step.
9. Run `aws configure` and input your...
    - AWS access key
    - AWS secret key
    - default region name (The Region of Your Host VM)
    - default output format (Output format is usually `json`)
    
9. Run `aws ec2 allocate-address --domain "vpc" --region <region name>`.
9. You should receive a text response like the one below.
    ```json
    {
        "PublicIp": "99.99.999.999",
        "AllocationId": "eipalloc-12345678",
        "Domain": "vpc"
    }
    ```
    Record the `PublicIP` in this response. This will be used for our Host VM.
9. Go back to the AWS Console. 
9. Select the top toolbar. Click **Service**. Then, click **EC2**.
9. In the sidebar under the **Network & Security** subsection, click the **Elastic IPs** link
9. In the table, find the Elastic IP you generated earlier.
9. Click in the **Actions** button on top of the table. Then, click **Associate Address**.
9. In the Instance textbox, put in the name of your Host VM.
9. Afterwards, click the caret the **Private IP** textbox. There should be only one ip in the dropdown. That is your Host VMs private IP. Click on that IP.
9. Finally, click **Associate**.

### 3. Add remaining settings to Security Group
Now that we created our Elastic IP. We can finish configuring our Security Group. 

9. Add settings in the table below to your own securty group.

|Type|Protocol|Port Range|Source|
|----|--------|----------|------|
|ALL TCP|TCP|0 - 65535|\<Elastic IP>|
|ALL TCP|TCP|0 - 65535|\<Name of your Security Group>|

### 4. Create your Host VM's Subdomain
Now we need to create a subdomain and link it to for Host VM. Your subdomain should contain your.
So if your name is Bob, your subdomain should be `bob.ucsc-cgp-dev.org`.

9. Select the top toolbar. Click **Service**. Then, click **Route 53**.
9. Click on **Hosted Zones** in the sidebar.
9. In the table, click on **ucsc-cgp-dev.org.** under the **Domain Name** column.
9. Click on the Blue **Create Record Set** button.
9. A form should appear on the right side of the screen. Put in your name in the **Name** text box in the form.
9. In the **Value** text box, put in the elastic IP of your host VM.
 
## Deploying the Platform

### 1 .Before Installation

9. Before you start deploying make sure the following components are already setup
    - Dos Azul Lambda
    - Boardwalk [README](boardwalk/README.md) for instructions on how to setup the external components.
    - Bagit Firecloud Lambda 
    
9. Write down the following information:
    - Your Docker Version in your host VM by using the bash command `docker -v`.
    - The hostname you created in Route 53
    - The region of your Hosy VM(e.g. `us-west-2`).
    - The location of the **SSH Key Pair** created after you created your Host VM.
    - Google Client ID from the Boardwalk setup
    - Google Client Secret from the Boardwalk setup
    - Google Site Verification Code from the Boardwalk setup
    - The azul-indexer elasticsearch endpoint url
    - The bagit firecloud lambda url
    - The dos azul lambda url

### 2. Running the Installer

9. Connect into your Host VM using the bash command `ssh ubuntu@<your Route 53 hotname> -i <location of your SSH Key Pair>`
9. Once you are connected to for Host VM, clone the *cgp-deployment* repo using
`git clone https://github.com/DataBiosphere/cgp-deployment.git`
9. Run `cd cgp-deployment` change your current directory to the repo root folder
9. Run `git checkout feature/commons` to switch to the Commons build of cgp-deployment
9. Run `sudo bash install_bootstrap` to start installing
9. Next, you will be asked to continue the script, so just answer `Y` to continue.
9. Then, you will be asked to install/upgrade Docker.
If you don't have Docker or your Docker versions is older than version 18.05.0-ce, 
answer yes please to install/upgrade Docker.
9. Afterwards, you will be asked to launch the public-facing nginx server.
The server is the **Commons** module that allows us to access **Boardwalk** and other components through the internet. Answer `Y` to Launch the server.
9. When it asks to launch the server in either `prod` or `dev` mode, type in `prod` mode.
9. Then, the bootstrapper will ask you if you want to run the boardwalk installer. Answer with `Y`.
9. Next, it will ask whether you want to run boardwalk on dev or prod. Type in `prod` mode.
9. You will be asked to input the following information in the corresponding order:
    9. the hostname of `dcc-dashboard`. This should be the url host you set in AWS Route 53.
    9. The Google Client ID when you created the Google App for Boardwalk
    9. The Google Client Secret when you created the Google App for Boardwalk
    9. The Google Site Verification Code from the Boardwalk setup
    9. The url of the Bagit Firecloud Lambda
    9. The url of the Dos Azul Lambda

Once the installer completes, the system should be up and running. Congratulations! See `docker ps` to get an idea of what's running.

### Other Notes 
  * Installing the Common module in `dev` mode will use letsencrypt's staging service, which won't exhaust your certificate's limit, but will install fake ssl certificates. `ptemprod` mode will install official SSL certificates.  

## Post-Installation

### Confirm Proper Function

To test that everything installed successfully, you can run `cd test && ./integration.sh`. This will do an upload and download with core-client and check the results.

### Troubleshooting

If something goes wrong, you can [open an issue](https://github.com/DataBiosphere/cgp-deployment/issues/new) or [contact a human](https://github.com/DataBiosphere/cgp-deployment/graphs/contributors).

### Tips

* This [blog post](https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes) is helpful if you want to clean up previous images/containers/volumes.

### To Do

* the bootstrapper should install Java, Dockstore CLI
