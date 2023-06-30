#!/bin/bash


# Pour lancer ce script: 
# 1 rendre le script est executable (a faire une seule fois) : chmod u+x start.sh
# 2 executer le script : ./start.sh


# Attention cette version est aussi à mettre à jour dans le fichier Dockerfile-Jenkins 
VERSION=2.361.4-1

sudo docker network ls | grep jenkins
if [ $? -ne 0 ]
then
   echo "creation du docker network jenkins"
   sudo docker network create jenkins
fi

sudo docker network ls | grep jenkins
if [ $? -eq 0 ]
then
   echo "docker network jenkins OK"
else
   echo "Erreur : le reseau docker jenkins n'existe pas !"
fi


echo "Build Jenkins Ocean ..."
sudo docker build -t myjenkins-blueocean:$VERSION -f ../Dockerfile .
if [ $? -eq 0 ]
then
   echo "Image jenkins-blueocean:$VERSION créée dans la base de registre"
else
   echo "Erreur lors de la creation image jenkins-blueocean:$VERSION !"
fi

sudo docker ps | grep jenkins-docker
if [ $? -eq 0 ]
then
   echo "Jenkins-docker deja demarre"
else
   sudo docker run --name jenkins-docker --rm --detach   --privileged --network jenkins --network-alias docker   --env DOCKER_TLS_CERTDIR=/certs   --volume jenkins-docker-certs:/certs/client   --volume jenkins-data:/var/jenkins_home   --publish 3000:3000 --publish 5000:5000 --publish 2376:2376   docker:dind --storage-driver overlay2

   sudo docker ps | grep jenkins-docker
   if [ $? -eq 0 ]
   then
      echo "Jenkins-docker OK"
   else
      echo "Erreur de demarrage de jenkins docker !"
   fi
fi

sudo docker ps | grep jenkins-blueocean
if [ $? -eq 0 ]
then
   echo "Jenkins Ocean deja demarre !!!"
else
   echo "Demarrage Jenkins Ocean en cours ..."
   sudo docker run --name jenkins-blueocean --detach   --network jenkins --env DOCKER_HOST=tcp://docker:2376   --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1   --publish 8080:8080 --publish 50000:50000   --volume jenkins-data:/var/jenkins_home   --volume jenkins-docker-certs:/certs/client:ro   --volume "$HOME":/home   --restart=on-failure   --env JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"   myjenkins-blueocean:$VERSION

   sudo docker ps | grep jenkins-blueocean
   if [ $? -ne 0 ]
   then
      echo "Erreur de demarrage de jenkins ocean !"
   fi
fi
