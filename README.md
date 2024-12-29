# DockerIonicCover

## DockerHub link

https://hub.docker.com/repository/docker/cartagodocker/ionic-cover

## Description

Image for loading a complete workspace to woek with ionic, angular, capacitor, gradle and android.

> This dockerfile use Ubuntu 24.04

## Create Image

````bash
docker build -t ionic-cover-image -f ./Dockerfile ./
````

## Create debug-container

````bash
docker run --rm -it --name ionic-cover-container ionic-cover-image
````

## Create debug-container for user 1000:1000

````bash
docker run --rm -it --name ionic-cover-container --user 1000:1000 ionic-cover-image
````

## Upload docker image to dockerhub

With github actions in repository it will be update automaticatlly in DockerHub with the tag of branches.

## To use in other docker images

Just add the next line in the Dockerfile to base the other image on this one.

````Dockerfile 
FROM cartagodocker/ionic-cover:latest
````
