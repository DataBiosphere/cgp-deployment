# Boardwalk
The core's file browser.

## Overview
Boardwalk is the core's file browser to display the metadata of files stored in redwood. It relies on two key components:
* The metadata-indexer
* The dashboard-service

The metadata-indexer pulls the metadata information from redwood and creates a donor oriented index. It then uses this index to create a file oriented index. Both of these indexes get loaded into elasticsearch. The dashboard-service then reads from elasticsearch and returns queries that can be used to populate the Boardwalk file browser. 

## Deployment
Deployment is done through the `install_bootstrap` script on the root directory. It will ask you a series of question to collect the information required to install boardwalk and its components.

### Create a Google Oauth2 app

Before proceeding, you must ensure that you have a Google OAuth2 app. Follow the instructions [here](http://bitwiser.in/2015/09/09/add-google-login-in-flask.html#creating-a-google-project) under "Creating A Google Project". 

If you don't want to enable login and token retrieval through the portal, you can just put some random string for the Google Client ID and Google Client Secret. 

Here is a summary of what you need to do in order to create a Google OAuth2 app:

* Go to the [Google Developer Console](https://console.developers.google.com/).
* On the upper left side of the screen, click on the drop down button.
* Create a project by clicking on the plus sign in the pop-up window.
* On the next pop up window, add a name for your project.
* Once you create it, click on the "Credentials" section on the left hand side.
* Click on the "OAuth Consent Screen". Fill out a product name and choose an email for the Google Application. Fill the rest of the entries as you see fit for your purposes, or leave them blank, as they are optional. Save it.
* Go to the "Credentials" tab. Click on the "Create Credentials" drop down menu and choose "OAuth Client ID".
* Choose "Web Application" from the menu. Assign it a name.
* Under "Authorized JavaScript origins", enter `https://<YOUR_SITE>`.
* Under "Authorized redirect URIs", enter `https://<YOUR_SITE>/gCallback`.
* Click "Create". A pop up window will appear with your Google Client ID and Google Client Secret. Save these. If you lose them, you can always go back to the Google Console, and click on your project; the information will be there. Keep these values stored in a safe location. Treat them as you would treat a credit card number.


### Development Mode

The boardwalk installer has the option to install boardwalk and its components in either development (dev) or production (prod) mode. If you are installing in production, skip this section and head to **Installation Questions**. Otherwise, keep reading.

To make deployment during development faster, the `install_bootstrap` script will clone [cgp-dashboard](https://github.com/DataBiosphere/cgp-dashboard), [cgp-dashboard-service](https://github.com/DataBiosphere/cgp-dashboard-service), and [cgp-boardwalk](https://github.com/DataBiosphere/cgp-boardwalk) under `cgp-deployment/boardwalk/` if it looks like you haven't already done so. (If you're working off a non-default branch in one of those repos, you're going to want to do this yourself.)

Once you run the installer, `docker-compose` will use dev.yml to set up boardwalk and its components. It will create the Docker images using the Dockerfiles located in each of the repositories listed above.

In addition, installing boardwalk in dev mode will also install kibana under `myexample.com/kibana/` to aid in debugging all things related to elasticsearch, as well as to help in making new queries and aggregations that may be necessary. 

### Checking Docker Containers

You can check which docker containers are running by doing `sudo docker ps`. If the installation was successful, you should see the following containers running:
```
boardwalk_dcc-dashboard-service_1
boardwalk_dcc-dashboard_1
boardwalk_nginx_1
boardwalk_boardwalk_1
boardwalk_db_1
```
