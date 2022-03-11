docker build -t "webserver" .
docker images
docker run -d -p 80:80 webserver /usr/sbin/apache2ctl -D FOREGROUND