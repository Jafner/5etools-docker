FROM httpd
COPY init.sh /init.sh
RUN apt-get update && \
apt-get upgrade && \
apt-get -y install curl p7zip-full
WORKDIR /usr/local/apache2/htdocs/
RUN mkdir download
ENV IMG false
CMD ["/bin/bash","/init.sh"]
