# cgp-deployment

## About

This repository contains our Docker-compose and setup bootstrap scripts used to create a deployment of the [UCSC Genomic Institute's](http://commons.ucsc-cgp.org) Computational Genomics Platform (CGP) for the NIH Data Commons Pilot on AWS. It uses, supports, and drives development of several key GA4GH APIs and open source projects. In many ways it is the generalization of the [PCAWG](https://dcc.icgc.org/pcawg) cloud infrastructure developed for that project and a potential reference implementation for the [NIH Commons](https://datascience.nih.gov/commons) concept.

## Components
The system has components fulfilling a range of functions, all of which are open source and can be used independently or together. The installation instructions are currently specific to AWS, but usage of other cloud service providers is planned for the future.

![Computational Genomics Platform architecture](docs/dcc-arch.png)

These components are setup with the install process available in this repository:

* [Boardwalk](boardwalk/README.md): our file browsing portal on top of Redwood

Related projects that are either already setup and available for use on the web or are used by components above:

* [Dockstore](https://dockstore.org): our workflow and tool sharing platform


### Launch an instance of an AWS EC2 virtual machine (VM)

Use the AWS console or command line tool to create a host virtual machine. While you do this make a note of your security group name and ID and ensure you can [connect via ssh](#sshconnect). We will refer to this virtual machine as the VM throughout the rest of the documentation. Ultimately the performance and size of the VM depends on the traffic you expect. (**Note:** We have had problems when uploading big files to Virginia (~25GB). If possible, set up your AWS anywhere else but Virginia.)

The following specification has worked well for a small-scale production environment :

* Ubuntu Server 16.04
* r4.xlarge
* 250GB disk

For development work the following specifications have worked well in the past:
* Ubuntu Server 16.04
* m5.large
* 60 GB disk


#### Configuring the ports in your VM
Open inbound ports on your security group. Use the table below as a guide. Make sure you add /32 to the *Elastic IP*.

| Type | Port | Source | Description |
| --- | --- | --- | --- |
| HTTP | 80 | 0.0.0.0/0 | |
| HTTP | 80 | ::/0 | |
| HTTPS | 443 | 0.0.0.0/0 | |
| HTTPS | 443 | ::/0 | |
| All TCP | 0 - 65535 | _Your VM's Elastic IP_ | |
| All TCP | 0 - 65535 | _Your Security Group ID_ | | 
| Custom TCP Rule | 9000 | _Your VM's Elastic IP_ | webservice port |
| Custom TCP Rule | 9200 | _Your VM's Elastic IP_ | Elasticsearch |
| SSH | 22 | 0.0.0.0/0 | |


#### <a name="makeip"></a>Create and assign an _Elastic IP_ for your VM 
1. Go to _AWS console_, _Compute_,  _EC2 Dashboard_. There click *running instances*. 
2. Find your VM and make it active by clicking anywhere in that line.
3. Under the drop-down *Actions*, go to *Networking*, *Manage IP Addreses*.
4. Click on *Allocate an Elastic IP*. It will automatically create an IP address and show it on the screen.
5. Write down that _Elastic IP_. At this point, whatever IP address is shown under IPv4 Public IP for your VM is not the current instance's IP address. Next you need to associate the _Elastic IP_ with your VM.
6. Back in _EC2 Dashboard_ go to *Elastic IPs*. The IP address just created should be in that list. Check it and under *Actions*, *Associate*, choose resource type "Instance", and choose your EC2 (e.g., searching by its name).
7.  <a name="sshconnect"></a>In _EC2 Dashboard_ make your VM active by clicking it. Then click _Connect_ on top. The example in that window shows you how to ssh into your VM from a terminal.


#### Adding a private/public key pair to your local machine
On your local machine add the key pair file under `~/.ssh/<your_key_pair>.pem`. This is typically the same key pair that you use to connect to your VM via SSH. This key pair needs to be created on the [AWS console](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) so Amazon is aware of it. Set the privileges of that key pair file to _read-by-user-only_ by `chmod 400 ~/.ssh/<your_key>.pem` so it is not publicly viewable.

####  <a name="makebucket"></a>Create an AWS S3 bucket for persistent storage of BDBag 
The NIH Data Commons (DCPPC) uses BDBags to move metadata from one platform to another. In _Boardwalk_ a BDBag is created by clicking _Export to FireCloud_. Once clicked the selected metadata are packaged in a BDBag, and the bag is uploaded to an S3 bucket. Therefore, part of the installation process is creating an S3 bucket.
Follow these steps to create it

1. In the AWS console head over to _S3_.
2. Click _Create bucket_. Name your bucket (needs to be a unique), set the region and click _Next_. Take note of the bucket name, you'll be asked for it later during the installation.
3. In the next two tabs, _Configure options_ and _Set permissions_, leave the default settings and click _Next_.
4. Review the settings, and click _Create bucket_.

Next we want to limit the lifecycle of objects in that bucket to 1 day (technically is only needs to exists for a few minutes). To do that, in _Amazon S3_

1. Search for the bucket you just created and click on it.
2. Go the _Management_ tab, and in there to the tab _Lifecycle_, _+ Add lifecycle rule_.
3. Name your rule (e.g., "limit to 1 day") and click _Next_.
4. Accept the default settings in tab _Transistions_, and click _Next_.
5. In the _Expiration_ tab, click _Current version_. That checks _Expire current version of object_. In the prompt enter "1" for expiration time of day from object creation. Click _Next_.
6. Review the settings. The scope should include the whole bucket. Click _Save_.


## Installing the Platform
### Collecting Information
The installation script (`install_bootstrap`) will prompt for several questions. To expedite the installation process it is useful to prepare for some of the answers beforehand. Here are a few pointers:

* Make sure you know what AWS region your VM runs in (e.g. `us-west-2`).
* Decide whether you want to create an instance for development or production as it might impact the size and therefore the cost of the host virtual machine (see above for recommendations).
* Find out whether your favorite editor is installed on the VM.
* Create a static IP address for your VM (AWS calls this _Elastic IP_). You find a short set of instructions above.
* You will be asked to provide an host domain that points to your EC2 instance. You need to know the name of the domain but at the time of installation the domain (or _record set_) does not have to be configured in _Route 53_.
* _Boardwalk_ has functionality to export metadata to Broad's FireCloud. In order to use it you need to provide your Google Cloud Platform credentials. Specifically you need the Google Client ID and the Google Client Secret (it's okay to leave the Google site verfication code empty). 
* You need to input the [AWS IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)'s _ access key ID_ and *secret_access_key*.
* You need to have the name of the [S3 bucket you created earlier](#makebucket) handy as the install script will ask for it. The name you input has to be the exact name you gave it when you created the bucket.
* All metadata reside in an Elasticsearch database. Make sure you have the domain name of that Elasticsearch instance handy.
* Have the domain name of the _dos-dss server_ handy.

### Running the Installer
Once you have collected the above information, clone the repository on VM and run the bootstrap script. Be sure to set your branch to `feature/commons` as these instruction are specific to this branch.

    $ git clone https://github.com/DataBiosphere/cgp-deployment.git
    $ cd cgp-deployment
    $ sudo bash install_bootstrap

The `install_bootstrap` script will ask you to configure each service interactively. Specifically, you need to decide on whether you require a production (`prod` mode) or a development (`dev` mode) environment. Note that this decision can be made for _Common_ and _Boardwalk_ independently. For details regarding _Boardwalk_ see the [README](boardwalk/README.md).

#### Installing in `prod` mode
Once the above steps have been completed we are now ready to install the components of the CGP.
In `prod` mode the installation will run the Docker containers for all of the components listed below from the respective images from *Quay.io*. The `nginx` docker will be built from the *nginx-image* directory.


#### Installing in `dev` mode
Setting up *Common* to run in `dev` mode will cause [Let's Encrypt](https://letsencrypt.org/) to issue fake SSL certificates, which won't exhaust your certificate's limit. Setting up *Boardwalk* to run in `dev` mode will first build then run the Docker containers `boardwalk_nginx`, `boardwalk_dcc-dashboard`, `boardwalk_dcc-dashboard-service`, and `boardwalk_boardwalk` from the images (see [here](https://github.com/DataBiosphere/cgp-deployment/blob/feature/update-readme/boardwalk/README.md#development-mode) for more details). In addition, the `nginx` image is built from the *nginx-dev* directory. If your work requires real SSL certificates during development, it is recommended to set up *Common* in `prod` mode, and *Boardwalk* in `dev` mode.
  
Once the installer completes, the system should be up and running. Congratulations! Execute `docker ps` to get an idea of which containers are running.


## Post-Installation

### Confirm Proper Function

To test that everything installed successfully, you can run `cd test && ./integration.sh`. This will do an upload and download with core-client and check the results.

### Troubleshooting

If something goes wrong, you can [open an issue](https://github.com/DataBiosphere/cgp-deployment/issues/new) or [contact a human](https://github.com/DataBiosphere/cgp-deployment/graphs/contributors).

### Tips

* This [blog post](https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes) is helpful if you want to clean up previous images/containers/volumes.

### To Do

* the bootstrapper should install Java, Dockstore CLI
* Consonance config.template includes hard-coded Consonance token, needs to be generated and written to .env file just like Beni does
