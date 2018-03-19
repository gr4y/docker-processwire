FROM ubuntu:xenial
MAINTAINER Sascha Wessel <swessel@gr4yweb.de>

# Install all Packages
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    wget unzip curl git apache2 php7.0 libapache2-mod-php7.0 php7.0 php7.0-cli php7.0-gd php7.0-json php7.0-ldap php7.0-mbstring php7.0-mysql php7.0-xml php7.0-xsl php7.0-zip php7.0-soap 

# Enable apache mods.
RUN a2enmod php7.0
RUN a2enmod rewrite

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose HTTP
EXPOSE 80

# Expose HTTPS
EXPOSE 143

# Download Composer installer
RUN wget https://getcomposer.org/installer -O composer-setup.php

# Verify Composer Installer
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

# Install Composer globally
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Create App Directory
RUN mkdir /var/www/app; cd /var/www/app

# Download and Unzip ProcessWire
RUN wget https://github.com/processwire/processwire/archive/master.zip -O processwire.zip; unzip processwire.zip; rm processwire.zip

# Install Dependencies
RUN composer install

# Update the default apache site with the config we created.
ADD apache.conf /etc/apache2/sites-enabled/000-default.conf

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND