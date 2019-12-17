#!/bin/bash

echo  -e "building prophet.."
#make build
docker-compose build

#echo -e "\nstarting notebook"
#make py-shell

echo -e "starting flask app.."
docker-compose up