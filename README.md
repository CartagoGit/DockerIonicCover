# DockerIonicCover

## Github

https://github.com/CartagoGit/DockerIonicCover

## DockerHub link

https://hub.docker.com/repository/docker/cartagodocker/ionic-cover

## Specifications

-   Ubuntu 24.04
-   Zsh
-   Node 22
-   Npm 11.0.0
-   Java 17
-   Gradle 8.11.1
-   Android API 35
-   Android Build Tools 34.0.0
-   Bun.js 1.1.42
-   Ionic CLI 7.2.0
-   Angular 19.0.6
-   Capacitor 6.2.0

## Description

Image for loading a complete workspace for ionic, angular, capacitor, gradle and android.

> This dockerfile use Ubuntu 24.04

> Zsh profile based in [`cartagodocker/zsh`](https://hub.docker.com/repository/docker/cartagodocker/zsh/general) dockerhub image.

> Bun and Fast Node Manager from [`cartagodocker/nodebun`](https://hub.docker.com/repository/docker/cartagodocker/nodebun/general) dockerhub image.

> This dockerfile has curl, unzip, wget, git, ssh installed.


---

# Usage

## Create Image

```bash
docker build -t ionic-cover-image -f ./Dockerfile ./
```

## Create debug-container

```bash
docker run --rm -it --name ionic-cover-container ionic-cover-image
```

## Create debug-container for user 1000:1000

```bash
docker run --rm -it --name ionic-cover-container --user 1000:1000 ionic-cover-image
```

## Upload docker image to dockerhub

With github actions in repository it will be update automaticatlly in DockerHub with the tag of branches.

## To use in other docker images

Just add the next line in the Dockerfile to base the other image on this one.

```Dockerfile
FROM cartagodocker/ionic-cover:latest
```

---

# For specific inner scripts or SSH specs:

Look the cartagodocker/zsh image documentation in the next link:

[`cartagodocker/zsh`](https://hub.docker.com/repository/docker/cartagodocker/zsh/general)