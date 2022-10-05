FROM ubuntu:20.04

RUN apt update -y
RUN apt install -y glusterfs-server glusterfs-client
RUN apt install curl -y