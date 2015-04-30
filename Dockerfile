FROM ubuntu:trusty
MAINTAINER Vincent Lombard <vincent.lombard@universite-lyon.fr>

# Set locale
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# First install apt needed utility package
RUN apt-get update && apt-get install -y \
    python-software-properties \
    software-properties-common wget \
    sudo \
    net-tools \
    git \
    vim \
    curl \
    zip \
    unzip \
    apache2 \
    supervisor

RUN curl -k -O http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc
RUN gpg --with-fingerprint  SWITCHaai-swdistrib.asc
RUN apt-key add SWITCHaai-swdistrib.asc
RUN echo 'deb http://pkg.switch.ch/switchaai/ubuntu trusty main' | sudo tee /etc/apt/sources.list.d/SWITCHaai-swdistrib.list > /dev/null
RUN apt-get update && apt-get install -y \
    shibboleth

#Ajout CA cert ActiveDirectory
#ADD ./CERT-CA.cer /etc/ssl/certs/java/CERT-CA.cer
#RUN (keytool -import -trustcacerts -alias ca-cert -file /etc/ssl/certs/java/CERT-CA.cer -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt)


ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Template with mustache mo
ADD mo /tmp/mo
ADD apache-sp.tmpl /etc/apache2/sites-available/apache-sp.tmpl
RUN cat /etc/apache2/sites-available/apache-sp.tmpl |/tmp/mo >/etc/apache2/sites-available/apache-sp.conf
ADD shibboleth2.tmpl /etc/shibboleth/shibboleth2.tmpl
RUN cat /etc/shibboleth/shibboleth2.tmpl |/tmp/mo >/etc/shibboleth/shibboleth2.xml

ADD attribute-map.xml /etc/shibboleth/attribute-map.xml
ADD sp-cert.pem /etc/shibboleth/sp-cert.pem
ADD sp-key.pem /etc/shibboleth/sp-key.pem

RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod headers
RUN a2enmod xml2enc
RUN a2enmod proxy_http
RUN a2dissite 000-default
RUN a2ensite apache-sp

EXPOSE 443
ENTRYPOINT [ "supervisord" ]

#docker run -i -t shibbolethspudl_shibbolethsp /bin/bash
#https://nuxeo.universite-lyon.fr/Shibboleth.sso/Login?target=https%3A%2F%2Fnuxeo.universite-lyon.fr%2Fnuxeo%2F
#https://ish.universite-lyon.fr/Shibboleth.sso/Login?target=https%3A%2F%2Fish.universite-lyon.fr%2Fnuxeo%2F

# Update/Upgrad all packages on each build
ONBUILD RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::=--force-confdef
