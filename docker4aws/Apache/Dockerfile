# Simple Apache Dockerfile
#
FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y apache2
CMD /usr/sbin/apache2ctl -D FOREGROUND
EXPOSE 80

docker build -t newserver .
docker run -d -p 80:80 newserver