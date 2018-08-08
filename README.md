# cgp-deployment

## About

This repository contains our Docker-compose and setup bootstrap scripts used to create a deployment of the [UCSC Genomic Institute's](http://commons.ucsc-cgp.org) Computational Genomics Platform (CGP) for AWS. It uses, supports, and drives development of several key GA4GH APIs and open source projects. In many ways it is the generalization of the [PCAWG](https://dcc.icgc.org/pcawg) cloud infrastructure developed for that project and a potential reference implementation for the [NIH Commons](https://datascience.nih.gov/commons) concept.

## Components

The system has components fulfilling a range of functions, all of which are open source and can be used independently or together.

![Computational Genomics Platform architecture](docs/dcc-arch.png)

These components are setup with the install process available in this repository:

* [Boardwalk](boardwalk/README.md): our file browsing portal on top of Redwood

Related projects that are either already setup and available for use on the web or are used by components above:

* [Dockstore](https://dockstore.org): our workflow and tool sharing platform
* Set-up directions are currently specific to AWS, but usage of other cloud service providers is planned for the future.


### Launch an instance of a AWS EC2 virtual machine (VM)

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


#### Adding a private/public key pair to your VM

In the VM add your key pair under `~/.ssh/<your_key_pair>.pem`. This is typically the same key pair that you use to connec to your VM via SSH. This key pair needs to be created on the [AWS console](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) so Amazon is aware of it. Set the privileges of that key pair file to _read-by-user-only_ by `chmod 400 ~/.ssh/<your_key>.pem` so it is not publicly viewable.


## Installing the Platform (CGP)
### Collecting Information

The installation script (`install_bootstrap`) will prompt for several questions. To expedite the installation process it is useful to prepare for some of the answers beforehand. Here are a few pointers:

* make sure you know what AWS region your VM runs in (e.g. `us-west-2`)
* decide whether you want to create an instance for development or production as it might impact the size and therefore the cost of the host virtual machine (see above for recommendations)
* find out whether your favorite editor is installed on the VM
* create a static IP address for your VM (AWS calls this _Elastic IP_); find a short set of instructions above
* you will be asked to provide an host domain that points to your EC2 instance; you need to know the name of the domain but at the time of installation the domain (or _record set_) does not have to be configured in _Route 53_
* _Boardwalk_ has functionality to export metadata to Broad's FireCloud; in order to use it you need to provide your Google Cloud Platform credentials; specifically you need the Google Client ID and the Google Client Secret (it's okay to leave the Google site verfication code empty)
* all metadata reside in an Elasticsearch database; make sure you have the domain name of that Elasticsearch instance handy
* have the domain name of the _dos-dss server_ handy

### Running the Installer

Be sure to set your branch to `feature/commons` as these instruction are specific to this branch. Once the above setup is done, clone this repository onto your server and run the bootstrap script. If needed checkout a particular branch or release tag you're interested after you execute the `git clone` command.

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
