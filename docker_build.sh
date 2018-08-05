#!/bin/bash
mkdir docker_images
docker build -tag="temporary_server:latest" .
docker save -o ./docker_images/temporary_server_image.tar temporary_server
