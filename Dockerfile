FROM httpd
COPY init.sh /init.sh
COPY healthcheck.sh /healthcheck.sh
RUN apt-get update && \
apt-get -y upgrade && \
apt-get -y install curl p7zip-full
WORKDIR /usr/local/apache2/htdocs/
RUN mkdir download
ENV IMG false
HEALTHCHECK --startperiod=1m CMD /healthcheck.sh 
CMD ["/bin/bash","/init.sh"]