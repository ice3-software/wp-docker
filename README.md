#Wordpress Docker Container

A simple little Dockerfile and associated boot script for a Wordpress Docker container. This container hosts Wordpress as well as an instance of MySQL.

Built whilst playing around / getting to grips with Docker.

###Usage

Build and run the container:

    docker build .

Run the container:

    docker run -d -p 80:80 -e SITE_URL=<your site URL> SITE_TITLE=<your site title>

What are the various configuration values?

    docker exec <container-id> cat /logs/environment_variables.log
