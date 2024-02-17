FROM httpd
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
COPY init.sh /init.sh
RUN apt-get update && \
apt-get -y upgrade && \
apt-get -y install curl git jq && \
chmod +x /init.sh

RUN echo "<Location /server-status>\n"\
"    SetHandler server-status\n"\
"    Order deny,allow\n"\
"    Allow from all\n"\
"</Location>\n"\
>> /usr/local/apache2/conf/httpd.conf

WORKDIR /usr/local/apache2/htdocs/
RUN chown -R $PUID:$PGID /usr/local/apache2/htdocs
CMD ["/bin/bash","/init.sh"]