FROM httpd
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
COPY init.sh /init.sh
COPY healthcheck.sh /healthcheck.sh
RUN apt-get update && \
apt-get -y upgrade && \
apt-get -y install curl p7zip-full && \
chmod +x /init.sh && \
chmod +x /healthcheck.sh
WORKDIR /usr/local/apache2/htdocs/
RUN mkdir download
RUN chown -R $PUID:$PGID /usr/local/apache2/htdocs
ENV IMG false
HEALTHCHECK --start-period=1m CMD /healthcheck.sh 
CMD ["/bin/bash","/init.sh"]