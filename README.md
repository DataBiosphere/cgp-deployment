# cgp-deployment

## About

This repository contains our Docker-compose and setup bootstrap scripts used to create a deployment of the [UCSC Genomic Institute's](http://ucsc-cgl.org) Computational Genomics Platform for AWS. It uses, supports, and drives development of several key GA4GH APIs and open source projects. In many ways it is the generalization of the [PCAWG](https://dcc.icgc.org/pcawg) cloud infrastructure developed for that project and a potential reference implementation for the [NIH Commons](https://datascience.nih.gov/commons) concept.

## Components

The system has components fulfilling a range of functions, all of which are open source and can be used independently or together.

![Computational Genomics Platform architecture](docs/dcc-arch.png)

These components are setup with the install process available in this repository:

* [Boardwalk](boardwalk/README.md): our file browsing portal on top of Redwood

These are related projects that are either already setup and available for use on the web or are used by components above:

* [Dockstore](https://dockstore.org): our workflow and tool sharing platform
* [Toil](https://github.com/BD2KGenomics/toil): our workflow engine, these workflows are shared via Dockstore

## Installing the Platform

These directions below assume you are using AWS.  We will include additional cloud instructions as `cgp-deployment` matures.

### Collecting Information

The installation script will prompt for several questions. It is useful to prepare for some of the answers beforehand to expedite the installation process. Here are a few pointers:

* make sure you know what region you're running in (e.g. `us-west-2`)
* decide whether you want to create an instance for development or production as it might impact the size and therefore the cost of the host virtual machine
* find out whether your favorite editor is installed on host virtual machine
* create a static IP address for your virtual machine (AWS calls this _Elastic IP_); find a short set of instructions below
* you will be asked to provide an host domain that points to your EC2 instance; at the time of installation that domain (or _record set_) does not have to be configured in _Route 53_.

### Launch an instance of a AWS EC2 virtual machine (VM)

Use the AWS console or command line tool to create a host virtual machine. While you do this make a note of your security group name and ID and ensure you can [connect via ssh](#sshconnect). We will refer to this virtual machine as the VM throughout the rest of the documentation. Ultimately the performance and size of the VM depends on the traffic you expect. For example the following specification has worked well for a small-scale production environment (**Note:** We have had problems when uploading big files to Virginia (~25GB). If possible, set up your AWS anywhere else but Virginia.):

* Ubuntu Server 16.04
* r4.xlarge
* 250GB disk

In `prod` mode the installation will run the Docker containers for all of the components listed below.

For development work the following specifications have worked well in the past:
* Ubuntu Server 16.04
* m5.large
* 60 GB disk

Setting up *Common* to run in `dev` mode will cause [Let's Encrypt](https://letsencrypt.org/) to issue fake SSL certificates. Setting up *Boardwalk* to run in `dev` mode will cause the Docker containers `boardwalk_nginx`, `boardwalk_dcc-dashboard`, `boardwalk_dcc-dashboard-service`, and `boardwalk_boardwalk` to be built from source (see [here](https://github.com/DataBiosphere/cgp-deployment/blob/feature/update-readme/boardwalk/README.md#development-mode) for more details). If your work requires real SSL certificates during development, it is recommended to set up *Common* in `prod` mode, and *Boardwalk* in `dev` mode.


#### <a name="makeip"></a>Create and assign an _Elastic IP_ for your VM 
1. Go to _AWS console_, _Compute_,  _EC2 Dashboard_. There click *running instances*. 
2. Find your VM and make it active by clicking anywhere in that line.
3. Under the drop-down *Actions*, go to *Networking*, *Manage IP Addreses*.
4. Click on *Allocate an Elastic IP*. It will automatically create an IP address and show it on the screen.
5. Write down that _Elastic IP_. At this point, whatever IP address is shown under IPv4 Public IP for your VM is not the current instance's IP address. Next you need to associate the _Elastic IP_ with your VM.
6. Back in _EC2 Dashboard_ go to *Elastic IPs*. The IP address just created should be in that list. Check it and under *Actions*, *Associate*, choose resource type "Instance", and choose your EC2 (e.g., searching by its name).
7.  <a name="sshconnect"></a>In _EC2 Dashboard_ make your VM active by clicking it. Then click _Connect_ on top. The example in that window shows you how to ssh into your VM from a terminal.


#### Adding private SSH key to your VM

Add your private ssh key under `~/.ssh/<your_key>.pem`, this is typically the same key that you use to SSH to your host VM, regardless it needs to be a key created on the AWS console so Amazon is aware of it. Then set privileges to _read-by-user-only_ by `chmod 400 ~/.ssh/<your_key>.pem` so your key is not publicly viewable.

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


#### TODO:

* Guide on choosing AWS instance type... make sure it matches your AMI.
* AMI, use an ubuntu 16.04 base box, you can use the official Ubuntu release.  You may need to make your own AMI with more storage! Needs to be in your region!  You may want to google to start with the official Ubuntu images for your region.

### Setup for Boardwalk

See the Boardwalk [README](boardwalk/README.md) for details.

### Running the Installer

Once the above setup is done, clone this repository onto your server and run the bootstrap script.

    $ git clone https://github.com/DataBiosphere/cgp-deployment.git
    $ cd cgp-deployment
    $ sudo bash install_bootstrap

Remember to checkout the particular branch or release tag that you're interested in if it's necessary.

#### Installer Question Notes

The `install_bootstrap` script will ask you to configure each service interactively.

* Boardwalk
  * Install in prod mode
* Common
  * Installing in `dev`mode will use letsencrypt's staging service, which won't exhaust your certificate's limit, but will install fake ssl certificates. `prod` mode will install official SSL certificates.
  
  
Once the installer completes, the system should be up and running. Congratulations! See `docker ps` to get an idea of what's running.

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
