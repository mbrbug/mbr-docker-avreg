FROM debian:buster

RUN DEBIAN_FRONTEND=noninteractive \
	&& apt-get update && apt-get install -y wget gnupg tzdata \
	&& wget -q -O - http://avreg.net/repos/avreg.public.key | apt-key add - \
	&& echo "deb http://avreg.net/repos/6.3-html5/debian/ buster main contrib non-free" >> /etc/apt/sources.list \
	&& rm -rf /usr/sbin/policy-rc.d && mkdir /etc/avreg && mkdir /video \
	&& echo "mysql-server mysql-server/root_password password 12345" | debconf-set-selections \
	&& echo "mysql-server mysql-server/root_password_again password 12345" | debconf-set-selections \
        && apt-get update && apt-get install -y rsyslog cron nano mariadb-server apache2 \
	&& service cron start && service apache2 start && service mysql start && service rsyslog start \
	&& apt-get install -y --allow-unauthenticated avreg-server-mysql \
        && service avreg stop \
	&& sed -i 's/db-user = '.*'/db-user = '"'avreg'"' /' /etc/avreg/avreg-mon.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'avreg'"' /' /etc/avreg/avreg-mon.secret \
	&& sed -i 's/db-user = '.*'/db-user = '"'avreg'"' /' /etc/avreg/avreg-unlink.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'avreg'"' /' /etc/avreg/avreg-unlink.secret \
	&& sed -i 's/db-user = '.*'/db-user = '"'avreg'"' /' /etc/avreg/avreg-site.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'avreg'"' /' /etc/avreg/avreg-site.secret \
	&& sed -i 's/db-user = '.*'/db-user = '"'avreg'"' /' /etc/avreg/avregd.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'avreg'"' /' /etc/avreg/avregd.secret \
	&& sed -i "s/; db-host = ''/db-host = '"'192.168.1.11'"'/" /etc/avreg/avreg.conf \
	&& sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/usr\/share\/avreg-site/' /etc/apache2/sites-available/000-default.conf \
	&& sed -i 's/\/avreg\/media/\/media/' /etc/avreg/site-apache2-user.conf \
	&& sed -i 's/\/var\/spool\/avreg/\/video/' /etc/avreg/site-apache2-user.conf \
	&& sed -i "s/avreg-site {/avreg-site {\nprefix = ''/" /etc/avreg/avreg.conf \
	&& sed -i "s/; storage-dir = '\/home\/avreg'/storage-dir = '\/video'/" /etc/avreg/avreg.conf \
	&& sed -i 's/server-name = ".*"/server-name = "homembr videoserver"/' /etc/avreg/avreg.conf \
	&& sed -i 's/Etc\/UTC/Europe\/Moscow/' /etc/timezone \
	&& sed -i 's/;date.timezone =/date.timezone = Europe\/Moscow/' /etc/php/7.2/apache2/php.ini \
	&& service mysql stop && apt-get purge -y mariadb-server \
        && usermod -u 1002 avreg && groupmod -g 503 avreg \
        && rmdir --ignore-fail-on-non-empty /var/lock/avreg \
        && rmdir --ignore-fail-on-non-empty /var/run/avreg

# Add crontab file in the cron directory
ADD files/crontab /etc/cron.d/avreg-unlink2

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/avreg-unlink2

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# entry point will start mysql, apache2, cron and avreg services and stop them as well on demand
ADD files/entry_point.sh /

RUN chmod +x /entry_point.sh

CMD ["/entry_point.sh"]

EXPOSE 80
