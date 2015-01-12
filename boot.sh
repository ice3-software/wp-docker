#!/bin/bash


#
# First thing's first, we need to start the mysql server
#
service mysql start


#
# Auto-generates a load of environment variables and injects them into
# the wordpress config file
#
SetupConfig(){

	alias pwgen='pwgen -c -n -1 65'

	export MYSQL_ROOT_PASSWORD=$(pwgen)
	export DB_NAME='wordpress'
	export DB_USER='wordpress_user'
	export DB_PASSWORD=$(pwgen)
	export DB_HOST='localhost'
	export WP_ADMIN_USER='wordpress_admin'
	export WP_ADMIN_PASSWORD=$(pwgen)
	export WP_ADMIN_EMAIL='admin@example.com'
	export WP_AUTH_KEY=$(pwgen)
	export WP_SECURE_AUTH_KEY=$(pwgen)
	export WP_LOGGED_IN_KEY=$(pwgen)
	export WP_NONCE_KEY=$(pwgen)
	export WP_AUTH_SALT=$(pwgen)
	export WP_SECURE_AUTH_SALT=$(pwgen)
	export WP_LOGGED_IN_SALT=$(pwgen)
	export WP_NONCE_SALT=$(pwgen)

	sed "s/%%DB_NAME%%/$DB_NAME/
		s/%%DB_USER%%/$DB_USER/
		s/%%DB_PASSWORD%%/$DB_PASSWORD/
		s/%%DB_HOST%%/$DB_HOST/
		s/%%WP_AUTH_KEY%%/$WP_AUTH_KEY/
		s/%%WP_SECURE_AUTH_KEY%%/$WP_SECURE_AUTH_KEY/
		s/%%WP_NONCE_KEY%%/$WP_NONCE_KEY/
		s/%%WP_AUTH_SALT%%/$WP_AUTH_SALT/
		s/%%WP_SECURE_AUTH_SALT%%/$WP_SECURE_AUTH_SALT/
		s/%%WP_LOGGED_IN_SALT%%/$WP_LOGGED_IN_SALT/
		s/%%WP_NONCE_SALT%%/$WP_NONCE_SALT/
		s/%%WP_LOGGED_IN_KEY%%/$WP_LOGGED_IN_KEY/" 	\
		/wp-config.php > $WP_CONFIG_PATH

	PrintGeneratedValues
}


#
# Prints out the various environment variables to the console and
# to our log file.
#
# Users can run
#
# 	docker exec <container-id> cat /logs/environment_vars.log
#
# on the container if they miss them.
#
PrintGeneratedValues(){

	LOG_FILE=$LOG_DIR/environment_vars.log

	echo -e															\
		"\nExported the application environment variables... some"	\
		"of these are autogenered so take note. They are also"  	\
		"written to $LOG_FILE\n\n"									\
		"---- Database Config ----\n\n"								\
		"- Name: $DB_NAME\n"										\
		"- User: $DB_USER\n"										\
		"- Password: $DB_PASSWORD\n"								\
		"- Root Password: $MYSQL_ROOT_PASSWORD\n"					\
		"- Host: $DB_HOST\n\n"										\
		"---- Wordpress Config ----\n\n"							\
		"- Admin User: $WP_ADMIN_USER\n"							\
		"- Admin Password: $WP_ADMIN_PASSWORD\n"					\
		"- Admin Email: $WP_ADMIN_EMAIL\n"							\
		"- Auth Key: $WP_AUTH_KEY\n"								\
		"- Secure Auth Key: $WP_SECURE_AUTH_KEY\n"					\
		"- Logged In Key: $WP_LOGGED_IN_KEY\n"						\
		"- Nonce Key: $WP_NONCE_KEY\n"								\
		"- Auth Salt: $WP_AUTH_SALT\n"								\
		"- Secure Auth Salt: $WP_SECURE_AUTH_SALT\n"				\
		"- Logged In Salt: $WP_LOGGED_IN_SALT\n"					\
		"- Nonce Salt: $WP_NONCE_SALT\n" |							\
		tee $LOG_FILE
}


#
# Sets the MySQL root password, creates wordpress database and wordpress
# user.
#
SetupDb(){

	mysqladmin -u root password $MYSQL_ROOT_PASSWORD
	mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \
		"CREATE DATABASE $DB_NAME;
		GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST'
		IDENTIFIED BY '$DB_PASSWORD'; FLUSH PRIVILEGES;"

}


#
# Installs a fresh wordpress application in the application directory.
# Note that if SITE_URL is not defined it will set it to the server's
# external IP and if SITE_TITLE is not defined it will default to
# "Example Wordpress"
#
SetupWordpress(){

	if [ -z "$SITE_URL" ]; then
		export SITE_URL=$(curl ipecho.net/plain ; echo)
		echo "Default SITE_URL=$SITE_URL"
	fi

	if [ -z "$SITE_TITLE" ]; then
		export SITE_TITLE="Example Wordpress"
		echo "Default SITE_TITLE=$SITE_TITLE"
	fi

	cd $APP_DIR
	wp core download --allow-root
	wp core install --allow-root 								\
		--title="$SITE_TITLE"									\
		--url="$SITE_URL"										\
		--admin_user="$WP_ADMIN_USER"							\
		--admin_password="$WP_ADMIN_PASSWORD"					\
		--admin_email="$WP_ADMIN_EMAIL"
}


#
# Is this the first time we're installing the wordpress application?
#
# We determine whether its a fresh install or the application volume
# data has persisted from a pervious container based on whether the
# wordpress config file exists at its specified path. We are
# affectively lazily installing a wordpress application
#
if [ ! -f $WP_CONFIG_PATH ]; then

	echo -e															\
		"\nNo wp-config found in the application directory,"		\
		"installing a fresh wordpress application."

	SetupConfig
	SetupDb
	SetupWordpress

fi


#
# Finaly, start apache in the foreground after we've lazily setup a
# wordpress installation
#
chown www-data:www-data $APP_DIR -R
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
