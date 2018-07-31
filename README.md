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

Make sure you know what region you're running in (e.g. `us-west-2`).

### Starting an AWS VM

Use the AWS console or command line tool to create a host. For example:

* Ubuntu Server 16.04
* r4.xlarge
* 250GB disk

We will refer to this as the host VM throughout the rest of the documentation. It will run the Docker containers for all of the components listed below.

You should make a note of your security group name and ID and ensure you can connect via ssh.

**Note** We have had problems when uploading big files to Virginia (~25GB). If possible, set up your AWS anywhere else but Virginia.

### AWS Tasks

Make sure you do the following:

* assign an Elastic IP (a static IP address) to your instance
* open inbound ports on your security group
    * 80 <- world
    * 22 <- world
    * 443 <- world
    * all TCP <- the elastic IP of the VM (Make sure you add /32 to the Elastic IP)
    * all TCP <- the security group itself

#### Adding private SSH key to your VM

Add your private ssh key under `~/.ssh/<your_key>.pem`, this is typically the same key that you use to SSH to your host VM, regardless it needs to be a key created on the AWS console so Amazon is aware of it. Then do `chmod 400 ~/.ssh/<your_key>.pem` so your key is not publicly viewable.

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

### Deep Dive

#### Authentication && Authorization

Currently, the Commons deployment of Boardwalk is only showing public access data. No authentication is required. It is only required to log on to take advantage of the [Export to FireCloud feature](#export-to-firecloud), and the requirement for this is going away.

However, since Boardwalk will be showing access controlled data, authentication and authorization will be required.

Here is a proposed interaction:

[Boardwalk Login](https://mermaidjs.github.io/mermaid-live-editor/#/view/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5wYXJ0aWNpcGFudCBCb2FyZHdhbGsgVUlcbnBhcnRpY2lwYW50IERhc2hib2FyZFxucGFydGljaXBhbnQgRGFzaGJvYXJkU2VydmljZVxucGFydGljaXBhbnQgVXNlciBEQlxuQm9hcmR3YWxrIFVJIC0-PiBHb29nbGUgOiBVc2VyIGNsaWNrcyBMb2dpbiBCdXR0b25cbkdvb2dsZSAtPj4gRGFzaGJvYXJkOiBHb29nbGUgcmV0dXJucyBhdXRob3JpemF0aW9uIGNvZGVcbkRhc2hib2FyZCAtPj4gR29vZ2xlOiBVc2luZyBBdXRob3JpemF0aW9uIGNvZGUsIHJlcXVlc3QgYWNjZXNzIGFuZCByZWZyZXNoIHRva2VuXG5EYXNoYm9hcmQgLT4-IERhc2hib2FyZDogR2V0IGVtYWlsIGZyb20gYWNjZXNzIHRva2VuXG5EYXNoYm9hcmQgLT4-IFVzZXIgREI6IFN0b3JlIGVtYWlsIChrZXkpIGFuZCB0b2tlbnNcbk5vdGUgcmlnaHQgb2YgVXNlciBEQjogSXMgdGhpcyBuZWNlc3Nhcnk_IEkgdGhpbmsgc28sIGluIG9yZGVyIHRvIHJlZnJlc2ggdGhlIGFjY2VzcyB0b2tlbi5cbkRhc2hib2FyZCAtPj4gQXV0aG9yaXphdGlvbiBTZXJ2aWNlOiBTZW5kIGFjY2VzcyB0b2tlbiB0byBBdXRoIFNlcnZpY2VcbkF1dGhvcml6YXRpb24gU2VydmljZSAtPj4gQXV0aG9yaXphdGlvbiBTZXJ2aWNlOiBHZXQgZW1haWwgZnJvbSB0b2tlbiwgY2hlY2sgaWYgZW1haWwgaXMgd2hpdGVsaXN0ZWRcbkF1dGhvcml6YXRpb24gU2VydmljZSAtPj4gRGFzaGJvYXJkOiAyMDAgb3IgNDAzIHN0YXR1cyBjb2RlIGJhc2VkIG9uIHdoZXRoZXIgZW1haWwgaXMgd2hpdGVsaXN0ZWRcbmFsdCBpcyAyMDBcbkRhc2hib2FyZCAtPj4gQm9hcmR3YWxrIFVJOiBSZWRpcmVjdCB0byBIb21lIFBhZ2VcbmVsc2VcbkRhc2hib2FyZCAtPj4gQm9hcmR3YWxrIFVJOiBSZWRpcmVjdCB0byBVbmF1dGhvcml6ZWQgUGFnZVxuZW5kXG4iLCJtZXJtYWlkIjp7InRoZW1lIjoiZm9yZXN0In19)


#### Export to FireCloud

Currently, Export to FireCloud is done by the CGP Boardwalk making API calls to FireCloud. This requires the user to login to Boardwalk; Boardwalk uses that token to make API calls, both directly from Dashboard Service, as well as from the Bagit FireCloud lambda.

[Current Export to FireCloud Diagram](https://mermaidjs.github.io/mermaid-live-editor/#/view/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5wYXJ0aWNpcGFudCBCb2FyZHdhbGsgVUlcbnBhcnRpY2lwYW50IERhc2hib2FyZFxucGFydGljaXBhbnQgVXNlciBEQlxucGFydGljaXBhbnQgRGFzaGJvYXJkU2VydmljZVxuQm9hcmR3YWxrIFVJIC0-PiBEYXNoYm9hcmQ6IEdFVCBodHRwczovL2NvbW1vbnMudWNzYy1jZ3AtZGV2Lm9yZy9ib2FyZHdhbGtcbkRhc2hib2FyZCAtPj4gQm9hcmR3YWxrIFVJOiBpbmRleC5odG1sXG5sb29wIExvYWQgQm9hcmR3YWxrIFNQQVxuICAgQm9hcmR3YWxrIFVJIC0-PiBEYXNoYm9hcmQ6IEdFVCBjc3MsIGpzLCAmIGh0bWwgdGVtcGxhdGVzXG5lbmRcbkJvYXJkd2FsayBVSSAtPj4gRGFzaGJvYXJkU2VydmljZTogUmVxdWVzdCBkYXRhLCBmYWNldHNcbkRhc2hib2FyZFNlcnZpY2UgLT4-IEVsYXN0aWNTZWFyY2g6IEZldGNoIGRhdGEsIGZhY2V0c1xuRWxhc3RpY1NlYXJjaCAtPj4gRGFzaGJvYXJkU2VydmljZTogUmV0dXJuIGRhdGEsIGZhY2V0c1xuRGFzaGJvYXJkU2VydmljZSAtPj4gQm9hcmR3YWxrIFVJOiBSZXR1cm4gZGF0YSwgZmFjZXRzXG5Cb2FyZHdhbGsgVUkgLT4-IEdvb2dsZTogVXNlciBDbGlja3MgTG9naW4gQnV0dG9uLCByZWRpcmVjdHMgdG8gR29vZ2xlXG5Hb29nbGUgLT4-IERhc2hib2FyZDogQXV0aG9yaXphdGlvbiBDb2RlIFNlbnQgdG8gIERhc2hib2FyZFxuRGFzaGJvYXJkIC0-PiBHb29nbGU6IERhc2hib2FyZCBSZXF1ZXN0cyBBY2Nlc3MgYW5kIFJlZnJlc2ggVG9rZW5zIHVzaW5nIEF1dGhvcml6YXRpb24gQ29kZVxuR29vZ2xlIC0-PiBEYXNoYm9hcmQ6IEdvb2dsZSByZXNwb25kcyB3aXRoIEFjY2VzcyBhbmQgUmVmcmVzaCBUb2tlbnNcbkRhc2hib2FyZCAtPj4gVXNlciBEQjogU3RvcmUgdXNlciBlbWFpbCwgYWNjZXNzIGFuZCByZWZyZXNoIHRva2Vuc1xuRGFzaGJvYXJkIC0-PiBCb2FyZHdhbGsgVUk6IEVuY3J5cHQgRmxhc2sgc2Vzc2lvbiBjb29raWUgd2l0aCBlbWFpbFxuQm9hcmR3YWxrIFVJIC0-PiBEYXNoYm9hcmQ6IFVzZXIgY2xpY2tzIEV4cG9ydCB0byBGQywgcmVxdWVzdCBzZW50IHdpdGggRmxhc2sgY29va2llXG5EYXNoYm9hcmQgLT4-IERhc2hib2FyZDogR2V0IGVtYWlsIGJ5IGRlY3J5cHRpbmcgRmxhc2sgc2Vzc2lvbiBjb29raWVcbkRhc2hib2FyZCAtPj4gVXNlciBEQjogTG9vayB1cCBVc2VyIHJvd1xuVXNlciBEQiAtPj4gRGFzaGJvYXJkOiBSZXR1cm4gdXNlciByb3dcbkRhc2hib2FyZCAtPj4gR29vZ2xlOiBHZXQgcmVmcmVzaCB0b2tlbiBmcm9tIHVzZXIgcm93LCBhbmQgcmVxdWVzdCBuZXcgYWNjZXNzIHRva2VuXG5EYXNoYm9hcmQgLT4-IERhc2hib2FyZFNlcnZpY2U6IENhbGwgL3JlcG9zaXRvcnkvZmlsZXMvZXhwb3J0L2ZpcmVjbG91ZCB3aXRoIGFjY2VzcyB0b2tlblxuRGFzaGJvYXJkU2VydmljZSAtPj4gRGFzaGJvYXJkU2VydmljZTogQ3JlYXRlIEJkQmFnXG5EYXNoYm9hcmRTZXJ2aWNlIC0-PiBCYWdpdCBGQyBMYW1iZGE6IFBvc3QgQkRCYWdcbkJhZ2l0IEZDIExhbWJkYSAtPj4gRmlyZUNsb3VkOiBSZWFkIEJEQmFnLCBpbnZva2UgRmlyZUNsb3VkIEFQSXMiLCJtZXJtYWlkIjp7InRoZW1lIjoiZm9yZXN0In19)

The model under development is that Boardwalk will create a BDBag in s3, get a pre-signed URL, then redirect to Saturn (the new FireCloud UI), with the presigned URL as a query parameter. The Saturn UI will take care of logging in, prompting the user for the workspace, etc. For purposes of exporting to FireCloud, since Boardwalk will no longer be making FireCloud API calls, users would not need to log in to Boardwalk. Note that for other reasons, log in will be required, but there will be no need from the export perspective. With this approach, the Bagit FireCloud lambda can be retired.

[Proposed Export to FireCloud Diagram](https://mermaidjs.github.io/mermaid-live-editor/#/view/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5wYXJ0aWNpcGFudCBCb2FyZHdhbGsgVUlcbnBhcnRpY2lwYW50IERhc2hib2FyZFNlcnZpY2VcbkJvYXJkd2FsayBVSSAtPj4gQm9hcmR3YWxrIFVJOiBVc2VyIGNsaWNrcyBFeHBvcnQgdG8gRkMgQnV0dG9uXG5Cb2FyZHdhbGsgVUkgLT4-IERhc2hib2FyZFNlcnZpY2U6IEFqYXggcmVxdWVzdCB0byBEYXNoYm9hcmQgU2VydmljZSByZXF1ZXN0aW5nIHNpZ25lZCBVUkwgdG8gQkRCYWdcbkRhc2hib2FyZFNlcnZpY2UgLT4-IERhc2hib2FyZFNlcnZpY2U6IERhc2hib2FyZCBTZXJ2aWNlIGdlbmVyYXRlcyBCREJhZ1xuRGFzaGJvYXJkU2VydmljZSAtPj4gQm9hcmR3YWxrIFVJOiBSZXR1cm5zIHByZXNpZ25lZCBVUkwgdG8gQkRCYWdcbkJvYXJkd2FsayBVSSAtPj4gRmlyZUNsb3VkOiBSZWRpcmVjdHMsIGluIGEgbmV3IHRhYiwgdG8gaHR0cHM6Ly9zYXR1cm51aT9iYWc9c2VsZlNpZ25lZFVybFxuIiwibWVybWFpZCI6eyJ0aGVtZSI6ImZvcmVzdCJ9fQ)
