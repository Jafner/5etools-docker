FROM httpd
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
COPY init.sh /init.sh
RUN apt-get update && \
apt-get -y upgrade && \
apt-get -y install curl p7zip-full megatools git jq && \
chmod +x /init.sh

RUN cat <<EOT >> /usr/local/apache2/conf/httpd.conf
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Allow from all
</Location>
EOT
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
WORKDIR /usr/local/apache2/htdocs/
RUN mkdir download
RUN chown -R $PUID:$PGID /usr/local/apache2/htdocs
ENV IMG false
CMD ["/bin/bash","/init.sh"]