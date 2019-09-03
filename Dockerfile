# Set the base image
FROM ubuntu:18.04

# File Author / Maintainer
LABEL maintainer="Yefry Figueroa | www.figueroa.it" 

# Set to no tty
ARG DEBIAN_FRONTEND=noninteractive

# Set the locale
RUN apt-get clean && apt-get update && \
    apt-get install -y locales=2.27-3ubuntu1 --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#Set PHP-FPM Version
ENV phpv 7.3

# Install NGINX, PHP $phpv, and supplimentary programs. 
RUN apt-get update && \
    apt-get -y install software-properties-common --no-install-recommends && \
    add-apt-repository ppa:ondrej/php && \
    add-apt-repository ppa:nginx/stable && \
    apt-get update && \
    BUILD_PACKAGES="nginx supervisor openssh-server mariadb-client php$phpv-fpm php$phpv-cli php$phpv-common php$phpv-mysql php$phpv-curl php$phpv-gd php$phpv-intl php$phpv-sqlite3 php$phpv-xmlrpc php$phpv-xsl php$phpv-mbstring php$phpv-bcmath php$phpv-xml php$phpv-soap php$phpv-zip curl vim wget rsync zip unzip git composer" && \
    apt-get -y install $BUILD_PACKAGES --no-install-recommends && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && apt-get autoclean -y

# Needed dirs per fare funzionare l'avvio dei servizi da supervisord
RUN mkdir /var/run/sshd /var/run/supervisor /var/run/php /var/run/nginx /root/.ssh && \
    rm -rf /var/www/html

# Install supplimentary programs
RUN apt-get -y install inetutils-ping inetutils-telnet net-tools --no-install-recommends 

# Update the PHP.ini file
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/max_execution_time = 30/max_execution_time = 120/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/max_input_time = 60/max_input_time = -1/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/; max_input_vars = 1000/max_input_vars = 20000/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/;date.timezone =/date.timezone = 'Europe\/Rome'/" /etc/php/$phpv/fpm/php.ini && \
    sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/$phpv/fpm/php.ini

# Opcache custom config
RUN echo "opcache.memory_consumption=128M" >> /etc/php/$phpv/fpm/conf.d/10-opcache.ini && \
    echo "opcache.blacklist_filename=/etc/php/$phpv/fpm/opcache-blacklist.txt" >> /etc/php/$phpv/fpm/conf.d/10-opcache.ini

# Opcache include Blacklist directory file
COPY configs/opcache-blacklist.txt /etc/php/$phpv/fpm/opcache-blacklist.txt

COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY configs/authorized_keys /root/.ssh/authorized_keys

# Update the default site with the config we created.
COPY configs/index.php /var/www/htdocs/index.php

COPY configs/nginx.conf /etc/nginx/nginx.conf
COPY configs/nginx-vhost.conf /etc/nginx/sites-available/default
RUN ls -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

COPY configs/php-fpm.conf.j2 /etc/php/$phpv/fpm/php-fpm.conf
COPY configs/www.conf /etc/php/$phpv/fpm/pool.d/www.conf

RUN sed -i "s/VERSION/$phpv/" /etc/php/$phpv/fpm/php-fpm.conf && \
    sed -i "s/VERSION/$phpv/" /etc/php/$phpv/fpm/pool.d/www.conf && \
    sed -i "s/VERSION/$phpv/" /etc/nginx/sites-enabled/default


RUN chown www-data:www-data /var/www/htdocs

#RUN service php7.0-fpm start

#Add volumes
VOLUME /var/www/htdocs

WORKDIR /var/www/htdocs

EXPOSE 22 80

CMD ["/usr/bin/supervisord"]