#!/bin/bash
mkdir docker_images
docker build -t temporary_server .
docker save -o ./docker_images/temporary_server_image.tar temporary_server
