#!/bin/bash

function deployHealthchecks(){
  export $(cat healthchecks.env | xargs)
  make healthchecks
}

function deployNginx(){
  make nginx
}

if [ -n "$1" ]
then
  if [ $1 = "healthchecks" ]
  then
    echo "deploying healthchecks"
    deployHealthchecks
  elif [ $1 = "nginx" ]
  then
    echo "deploying NGINX"
    deployNginx
  else
    echo "deploy command not recognized!"
  fi
else
  echo "enter a specific deploy command"
  exit 1
fi