FROM mysql/mysql-server:latest
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

RUN yum install -y which 
RUN yum clean all
