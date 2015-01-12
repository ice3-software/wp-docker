
FROM ubuntu:14.04
MAINTAINER Steve Fortune <steve.fortune@icecb.com>


# Install basic packages

RUN apt-get update &&         \
 	apt-get -y install        \
    mysql-server              \
    mysql-client              \
	git                       \
	apache2                   \
	libapache2-mod-php5       \
	php5-mysql                \
	php5-curl                 \
	pwgen                     \
	php-apc                   \
	php5-mcrypt               \
	curl                      \
    sendmail

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp


# Static environment variables

ENV APP_DIR /var/www/wp
ENV LOG_DIR /logs
ENV WP_CONFIG_PATH $APP_DIR/wp-config.php
ENV MYSQL_DIR /var/lib/mysql


#Copy resources over to the server

ADD ./boot.sh /boot.sh
RUN chmod 655 /boot.sh
ADD ./wp-config.php /wp-config.php
RUN chmod 655 boot.sh
ADD ./apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
RUN mkdir -p $APP_DIR
RUN mkdir -p $LOG_DIR


# Mount our volumes: the mysql data storage directory and the wordpress application
# directory. The wordpress application data needs to persist in-between installations

VOLUME ["/var/lib/mysql", "/etc/mysql", "$APP_DIR", "$LOG_DIR"]


# Fire with our custom boot script

CMD ["/boot.sh"]
