#!/bin/bash

def_cont_name=face_recog_container

helpFunction()
{
   echo ""
   echo "Usage: $0 -p port"
   echo -e "\t-p http_port"
   exit 1 # Exit script after printing help
}

while getopts "p:" opt
do
   case "$opt" in
      p ) port="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$port" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo "Stopping and removing docker container 'face_recog_container' if it is running on port $port"
echo "Ignore No such container Error messages"
docker stop "$def_cont_name" || true
docker rm "$def_cont_name" || true

docker run \
      -ti --rm \
      -p "0.0.0.0:$port:8080" \
      -v "$PWD/data:/app/data" \
      --name "$def_cont_name" \
      -e TEMP_DOWNLOAD_URL='/src/app/.data_cache' \
      face_recog
