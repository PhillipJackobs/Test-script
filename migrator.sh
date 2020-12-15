#!/bin/bash

# FUNCTIONS
function mainmenu() { #Main menu/Migration wizard
while true; do
	read -p " 
Select migration process. 

[1] Wget/Backup
[2] All in one 
[3] WPEngine
[4] Exit

Note: When in doubt, press [b] to go back to the main menu.

-bash-4.2$ " migration_process 
	case "$migration_process" in
		[z])
php_modules exec on
;;
		[1]) #WGET/CPANEL
echo "This is best suited for Cpanel migrations. To make it work you need only to create the backup and upload the expored SQL here.

Here are the steps in case if you don't know what I will be doing:
1 - Checking files - check for any backups and if there are none, you will be guided through the wget wizard.
2 - Download and unzip the backup. (zip recommended)
3 - Look for a working wp-cofig.php password from other websites, checking database paths and plugins/functions.
4 - Import and edit the database - this means that you should not import the database in phpmyadmin.
5 - Install W3 Total cache in case if the client wants, or if you click y when asked.
6 - Scan the website for malware.
7 - Leave notes for the migration ticket.
"
			if check_for_files
				extract_files
				wp_config
				check_for_db
				check_old_path
				import_database
				check_plugins
				w3tcc
				scanit ; then
				notes 
				bai
			else
				echo "Error"
			fi
			;;
		[2]) #ALLINONE
echo "You can either install Wordpress and upload the AIO backup, or none of it. The wizard will guide you and do everything for you.

TLDR, I will:
1. Check and install Wordpress if there is none.
2. Check for .wpress backup which should be in the public_html. If there isn't any, I will ask you for a backup URL to download.
3. Ask a couple of questions regarding w3tc, www or non-www and if I should delete AIO after the migration is complete.
4. Install and restore the backup with All in one WP migration.
5. Check plugins/functions.
6. Scan for malware.
7. Leave migration notes.
"
			if allinone
				check_plugins
				w3tcc
				scanit ; then
				notes 
				bai
			else
				echo "Error"
			fi
			;;
		[3]) #WPENGINE
echo "Input your WPEngine backup link and then enter password and database name. The mighty migrator will do everything else for you."
			if wpe
			check_plugins
			w3tcc
			wpx user delete wpengine --yes
			scanit ; then
			notes
			bai
			else
				echo "Error"
			fi
			;;		
		[4]) #Main menu exit option.
			clear
			bai
			;;
		*)
			echo "Error! Please select a valid option." #Main manu Error.
			;;
	esac
done
}

function check_for_files(){ #Checks for any zip/tar/gz files, if there are no backups, it will redirect to the wget wizard
countfiles=`find . -type f  -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar" -o -name "*.gz" | wc -l`
echo "Checking for backups..."
sleep 1
	if [[ $countfiles = 0 ]]; then
			echo "No backups detected."
			sleep 1
			echo "Choose how to download your backup."
			download_files #wget wizard
			check_for_files #we need this after we download the files, to check again and assign the backup to $backupfile
	elif [[ $countfiles = 1 ]]; then 
			echo "Backup detected: `find . -type f  -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar" -o -name "*.gz" | cut -c 3-`"
			backupfile=`find . -type f  -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar" -o -name "*.gz"`
	else
		echo ""
		ls #in case if there are 2 or more zip files, this will list them and the user chooses which zip to use for the migration.
		echo ""
		read -p "Select zip or press [d] to download your backup: " backupfile
		if [[ "$backupfile" = "b" ]]; then
			mainmenu
		elif [[ "$backupfile" = "d" ]]; then
			download_files 
			check_for_files #we need this 
		echo "Backup selected: $Selected_backup"
	fi
	fi
}
function download_files() {
while true; do
	echo " "
	read -p "[1]FTP or [2]Direct URL? " how_to_download
		if [[  "$DIRECT" = "2"  ]]; then
			echo "To make this work, you need to:

Simply upload your backup here.

1. Disable the DNS zone in Virtualmin.
2. Paste the link without typing wget/curl.
3. Enable the DNS zone after the download is complete.
3. Upload the SQL file in public_html (if it's not included in the backup).

Note: When in doubt, press [b] to go back or [s] to skip and proceed.
"					
			while true; do
				read -p "Download link: " download_link
					if [[ -z "$download_link" ]]; then
					 	continue
					fi 
					if [[ "$download_link" = "b" ]]; then
						mainmenu
					fi
					if wget $DIRECTURL ; then
						echo "Download complete!"
					else
						echo "Error, select a valid option."
						continue
					fi
				break
			done
		elif [[ "$how_to_download" = "1" ]]; then #wget wizard	
			echo "To make this work, you need to:

1. Create backup on the old host (zip format)
2. Create FTP account.
3. Upload the SQL file in public_html (if it's not included in the zip).
4. Enter the details below for wget and wp-config.php.
"
			echo "Example:
IP on the old host: 420.04.20.420
FTP Username: wpx@example.com
FTP Password: your FTP password
Path to the backup after logging in FTP: /public_html/new.zip
Cut dirs: 1 

Note: When in doubt, press [b] to go back or [s] to skip and proceed.
"
			while true; do
				read -p "IP on the old host: " HOSTNAME
					if [[ -z "$HOSTNAME" ]]; then
					 	continue
					fi 
					if [[ "$HOSTNAME" = "b" ]]; then
						mainmenu
					fi
				read -p "FTP Username: " USERNAME 
					if [[ -z "$USERNAME" ]]; then
					 	continue
					fi
					if [[ "$USERNAME" = "b" ]]; then
						mainmenu
					fi
				read -p "FTP Password: "  PASSWORD
					if [[ -z "$PASSWORD" ]]; then
					 	continue
					fi
					if [[ "$PASSWORD" = "b" ]]; then
						mainmenu
					fi
				read -p "Path to the backup: " PATHZIP
					if [[ -z "$PATHZIP" ]]; then
					 	continue
					fi
					if [[ "$PATHZIP" = "b" ]]; then
						mainmenu
					fi
				read -p "Cut dirs (default 1): " CUTDIRS 
					if [[ -z $CUTDIRS ]]; then
						CUTDIRS=1
					fi
					if [[ "$CUTDIRS" = "b" ]]; then
						mainmenu
					fi
					if wget -m -nH --cut-dirs=$CUTDIRS --ftp-user=$USERNAME --ftp-pass=$PASSWORD  ftp://"$HOSTNAME""$PATHZIP" ; then
						echo "Download complete!"
					else
						echo "Error, please try again!"
						continue
					fi
				break 
			done
		elif [[ "$how_to_download" = "b" ]]; then
			mainmenu
		else
			echo "Error, please try again!"
			continue
		fi
	break
done
}

function extract_files() { #unzip, checks if htaccess exists, permissions...
echo "Extracting files..."
sleep 3
	if unzip -q $backupfile ; then
		echo "Done"
	elif tar xfz $backupfile 2>/dev/null ; then
		echo "Done"
	elif gzip -d $backupfile ; then
		echo "Done"
	else 
		echo "Error, please check the backup file."
		exit
	fi
no_htaccess
echo "Fixing permissions..."
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +
find . -type f -name ".listing*" -exec rm {} +
find . -type f -name "php.ini*" -exec rm {} +
find . -type f -name "*error_log*" -exec rm {} +
}

function wp_config() { #checks (up to 5 times) for any working wp-config password to connect to the mysql server, if not found then simply type/paste it.
config_pass1=`find ~/public_html/ ~/domains/*/public_html/ -name "wp-config.php" -exec grep -E 'DB_PASSWORD' {} \; 2>/dev/null | awk -F\' '{print $4}' | head -1`
config_pass2=`find ~/public_html/ ~/domains/*/public_html/ -name "wp-config.php" -exec grep -E 'DB_PASSWORD' {} \; 2>/dev/null | awk -F\' '{print $4}' | head -2 | tail -1`
config_pass3=`find ~/public_html/ ~/domains/*/public_html/ -name "wp-config.php" -exec grep -E 'DB_PASSWORD' {} \; 2>/dev/null | awk -F\' '{print $4}' | head -3 | tail -1`
config_pass4=`find ~/public_html/ ~/domains/*/public_html/ -name "wp-config.php" -exec grep -E 'DB_PASSWORD' {} \; 2>/dev/null | awk -F\' '{print $4}' | head -4 | tail -1`
config_pass5=`find ~/public_html/ ~/domains/*/public_html/ -name "wp-config.php" -exec grep -E 'DB_PASSWORD' {} \; 2>/dev/null | awk -F\' '{print $4}' | tail -1`
	if mysql -u$USER -h localhost -p$config_pass1 -e 'show databases;' 2>/dev/null; then
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	elif mysql -u$USER -h localhost -p$config_pass2 -e 'show databases;' 2>/dev/null; then
		config_pass1=$config_pass2
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	elif mysql -u$USER -h localhost -p$config_pass3 -e 'show databases;' 2>/dev/null; then
		config_pass1=$config_pass3
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	elif mysql -u$USER -h localhost -p$config_pass4 -e 'show databases;' 2>/dev/null; then
		config_pass1=$config_pass4
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	elif mysql -u$USER -h localhost -p$config_pass5 -e 'show databases;' 2>/dev/null; then
		config_pass1=$config_pass5
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	else
		read -s -p "Enter password: " config_passlegit
		config_pass1=$config_passlegit
		echo ""
		mysql -u$USER -h localhost -p$config_pass1 -e 'show databases;'
		read -p "Where do I import the database? " datadatabasesql
		echo "Selected database: $datadatabasesql"
	fi
sed -i "s+^.*DB_NAME.*$+define('DB_NAME', '$datadatabasesql');+" wp-config.php #edit wp-config file with the default $USER and a working config password, the DB_name is still checked manually, pls optimize.
sed -i "s+^.*DB_USER.*$+define('DB_USER', '$USER');+" wp-config.php
sed -i "s+^.*DB_PASSWORD.*$+define('DB_PASSWORD', '$config_pass1');+" wp-config.php
sed -i "s+^.*DB_HOST.*$+define('DB_HOST', 'localhost');+" wp-config.php
}

function no_htaccess() { #sometimes when there isn't a htaccess file, this will check and create one
if [[ -f ".htaccess" ]]; then
		echo " "
else
	cat <<EOT>> .htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
RewriteEngine on
RewriteCond %{HTTPS} !=on [NC]
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>
EOT
fi
}

function check_for_db() { #searches the current directory for any .sql files to use for the migration
while true; do
	countdb=`find . -maxdepth 1 -type f  -name "*.sql" | wc -l`
	if [[ $countdb = 0 ]]; then
		echo "Error no database detected."
		echo "Please import the SQL file and proceed."
		read -s -p "Press any key to continue... " any_key
		echo " "
			if [[ "$any_key" = "b" ]]; then
				mainmenu
			fi
		continue
	elif [[ $countdb = 1 ]]; then
		databasesql=`find . -maxdepth 1 -type f  -name "*.sql" | cut -c 3-`
		echo "Selected database SQL: $databasesql"
		break
	else
		echo "Select SQL database:"
		find . -maxdepth 1 -type f  -name "*.sql" | cut -c 3-
		echo ""
		read -p "Database: " databasesql
		echo "Selected database SQL: $databasesql"
		break
	fi
done
}

function check_old_path() { #checks the paths of the old host by using grep and the database sql in $databasesql
old_path=`grep -Eo "\/(home|home\d|home\d\d|nas|var|html|root|www|httpdocs)\/.*\/wp-content\/" $databasesql | sed -e 's/ *$//' | tr ',' '\n' | tr ';' '\n' | tr ':' '\n' | tr '"' '\n' | tr '%' '\n' | grep -E "\/(home|home\d|home\d\d|nas|var|html|root|www|httpdocs)\/.*\/wp-content\/" | sort -nu | rev | sed -e 's+.*tnetnoc-pw\/++g' | rev`
echo "Old path: $old_path"
echo "New path: `pwd`"
}

function import_database() { #imports the database and replaces the baths
echo "Importing database..."
	if wpx db import $databasesql ; then
		echo "Done"
		wpx search-replace $old_path `pwd` --all-tables --quiet >/dev/null 2>&1
		echo "Database paths replaced successfully."
	else
		echo "Error, could not import $databasesql."
		echo "Please double check the database, if necessary export it again from the old host."
	fi
}

function check_plugins(){ #checks plugins, functions, modules etc.
rm -rf wp-content/mu-plugins/
rm -rf wp-content/cache/
rm -rf wp-content/object-cache.php
wpx plugin list
	if [[ -d "./wp-content/plugins/sg-cachepress" ]]; then
		echo "SG-Optimizer detected!"
		echo "This plugin is designed to work only on SiteGround Servers."
		wpx plugin delete sg-cachepress
	fi
	if [[ -d "./wp-content/plugins/jetpack" ]]; then
		echo "Jetpack detected!"
		echo -e "<Files ~ "xmlrpc.php">
   Order allow,deny
   Allow from all
</Files>" | cat - .htaccess >temp && mv temp .htaccess
		echo -e "Success: Jetpack rule added."
	fi	
	if [[ -d "./wp-content/plugins/wordfence" ]]; then
		echo "Wordfence detected!"
		echo -e "<IfModule rewrite_module>
RewriteEngine On
RewriteRule .* - [E=noabort:1]
</IfModule>
<IfModule mod_security2.c>
    SecRuleRemoveById 9812280
</IfModule>" | cat - .htaccess >temp && mv temp .htaccess
		echo "Success: Wordfence rule whitelisted."
	fi
	if [[ -d "./wp-content/plugins/ewww-image-optimizer" ]]; then 
			echo "EWWW Imae Optimizer detected!"
			php_modules exec on
		fi
	if grep -q /var/lib/sec/wp-settings.php wp-config.php wp-config.php; then
		sed -i "s+^.*/var/lib/sec/wp-settings.php.*$+#@include_once('/var/lib/sec/wp-settings.php'); // Added by SiteGround WordPress management system+" wp-config.php
	fi
	if [[ -f "wordfence-waf.php" ]]; then
		sed -i "s+^.*file_exists.*$+if (file_exists('`pwd`/wp-content/plugins/wordfence/waf/bootstrap.php')) {+" wordfence-waf.php
		sed -i "s+^.*WFWAF_LOG_PATH.*$+define("WFWAF_LOG_PATH", '`pwd`/wp-content/wflogs/');+" wordfence-waf.php
		sed -i "s+^.*include_once.*$+include_once '`pwd`/wp-content/plugins/wordfence/waf/bootstrap.php';+" wordfence-waf.php
		echo "Success: 'wordfence-waf.php' paths replaced."
	fi
	if [[ -f .user.ini ]]; then
		sed -i "s+^.*auto_prepend_file.*$+auto_prepend_file = '`pwd`/wordfence-waf.php';+" .user.ini
	fi
	for htaccess in $(ls .htaccess); do
		if grep -q auto_prepend_file ${htaccess}; then
			sed -i "s+^.*auto_prepend_file.*$+php_value auto_prepend_file '`pwd`/wordfence-waf.php'+" .htaccess
		fi
	done
	for htaccess in $(ls .htaccess); do
		if grep -q AddHandler ${htaccess}; then
			echo "AddHandler detected!"
			sed -i "s+^.*AddHandler.*$+#AddHandler application/x-httpd-ea-php74 .php .php7 .phtml+" .htaccess
		fi
	done
		if grep -q WPCACHEHOME wp-config.php; then
			sed -i "s+^.*WPCACHEHOME.*$+define('WPCACHEHOME', '`pwd`/wp-content/plugins/wp-super-cache/');+" wp-config.php
			echo "Success: WP-super-cache paths changed."
		fi	
#REMOVE shady stuff from wp-config :/
sed -i "/.*MEMORY.*/d" wp-config.php
sed -i "/.*memory.*/d" wp-config.php
sed -i "/.*max_input_.*/d" wp-config.php
sed -i "/.*MAX_INPUT_.*/d" wp-config.php
sed -i "/.*MAX_EXECUTION_TIME.*/d" wp-config.php
sed -i "/.*max_execution_time.*/d" wp-config.php
sed -i "/.*post_max_.*/d" wp-config.php
sed -i "/.*POST_MAX_.*/d" wp-config.php
sed -i "/.*upload_max_.*/d" wp-config.php
sed -i "/.*UPLOAD_MAX_.*/d" wp-config.php
sed -i "/.*define('FS_CHMOD_DIR', (0775 & ~ umask()));.*/d" wp-config.php
sed -i "/.*define('FS_CHMOD_FILE', (0664 & ~ umask()));.*/d" wp-config.php
}

function w3tcc(){ #in case if the clients wants or doesn't want w3tc/autoptimize when migrating to WPX
while true; do #purposefully made in loop since we want an accurate answer, y or n.
	read -p "W3 Total Cache and Autoptimize? [y/n]: " CACHING
		if [[ -z $CACHING ]]; then
			echo "OK"
		elif [[  "$CACHING" = "y"  ]]; then
			echo "OK"
		elif [[ "$CACHING" = "n" ]]; then
			echo "OK"
		elif [[ "$CACHING" = "b" ]]; then
			mainmenu
		else 
			echo "Error!"
			continue
		fi
	break
done
	if [[  "$CACHING" = "y"  ]]; then
		if wpx plugin is-active wp-rocket ; then
			echo "Deactivating wp-rocket..."
			wpx plugin deactivate wp-rocket >/dev/null 2>&1
		fi
		if wpx plugin is-active litespeed-cache ; then
			echo "Deactivating litespeed-cache..."
			wpx plugin deactivate litespeed-cache >/dev/null 2>&1
		fi
		if wpx plugin is-active nitropack ; then
			echo "Deactivating nitropack..."
			wpx plugin deactivate nitropack >/dev/null 2>&1
		fi
		if wpx plugin is-active wp-super-cache ; then
			echo "Deactivating wp-super-cache..."
			wpx plugin deactivate wp-super-cache >/dev/null 2>&1
		fi
		if wpx plugin is-active wp-fastest-cache ; then
			echo "Deactivating wp-fastest-cache..."
			wpx plugin deactivate wp-fastest-cache >/dev/null 2>&1
		fi
		if wpx plugin is-active wp-fastest-cache-premium ; then
			echo "Deactivating wp-fastest-cache-premium..."
			wpx plugin deactivate wp-fastest-cache-premium >/dev/null 2>&1
		fi
	wpx plugin install w3-total-cache --quiet >/dev/null 2>&1
	wpx plugin activate w3-total-cache --quiet >/dev/null 2>&1
	rm -rf wp-content/advanced-cache.php
	wpx w3-total-cache fix_environment --quiet >/dev/null 2>&1
	wget -q http://omg.doyouevencode-bro.cloud/WPX_W3TC_Recommended_Settings_v6.json
	wpx w3-total-cache import WPX_W3TC_Recommended_Settings_v6.json --quiet >/dev/null 2>&1
	wpx w3-total-cache flush all --quiet >/dev/null 2>&1
	rm WPX_W3TC_Recommended_Settings_v6.json
	echo "Success: W3 Total Cache has been installed and configured."
	wpx plugin install autoptimize --quiet >/dev/null 2>&1
	wpx plugin activate autoptimize --quiet >/dev/null 2>&1
	wpx option update autoptimize_cache_clean 0 --quiet >/dev/null 2>&1
	wpx option update autoptimize_cdn_url "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css on --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_aggregate on --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_datauris "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_defer "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_defer_inline "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_exclude "wp-content/cache/, wp-content/uploads/, admin-bar.min.css, dashicons.min.css" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_include_inline  on --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_inline "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_css_justhead "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_html_keepcomments '' --quiet >/dev/null 2>&1
	wpx option update autoptimize_imgopt_launched on --quiet >/dev/null 2>&1
	wpx option update autoptimize_js on --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_aggregate on --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_exclude  "seal.js, js/jquery/jquery.js" --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_forcehead "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_include_inline "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_justhead "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_js_trycatch "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_optimize_checkout "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_optimize_logged "" --quiet >/dev/null 2>&1
	wpx option update autoptimize_show_adv 1 --quiet >/dev/null 2>&1
	echo "Success: Autoptimize has been installed and configured."
		elif [[ "$CACHING" = "n" ]]; then
			echo "Done"
		fi
}

function scanit() { #checksum & scan
wpx checksum core
echo "Scanning for infected files..."
ionice -c3 nice clamscan -ri --database=/var/lib/clamav/custom/ -l scan_results.txt
rm scan_results.txt
}

function notes() { #prints the macro for the migration ticket +NS/A records +notes
	value=`dig $(hostname) +short` #checks the server IP
		if	[[ "$value" = "67.202.92.24" ]]; then
			NS1=ns62.wpx.net
			NS2=ns63.wpx.net
		elif [[ "$value" = "67.202.92.23" ]]; then
			NS1=ns58.wpx.net
			NS2=ns59.wpx.net
		elif [[ "$value" = "67.202.92.22" ]]; then
			NS1=ns56.wpxhosting.com
			NS2=ns57.wpxhosting.com
		elif [[ "$value" = "67.202.92.21" ]]; then
			NS1=ns52.wpxhosting.com
			NS2=ns53.wpxhosting.com
		elif [[ "$value" = "67.202.92.20" ]]; then
			NS1=ns50.wpxhosting.com
			NS2=ns51.wpxhosting.com
		elif [[ "$value" = "67.202.92.19" ]]; then
			NS1=ns46.wpxhosting.com
			NS2=ns47.wpxhosting.com
		elif [[ "$value" = "67.202.92.18" ]]; then
			NS1=ns44.wpxhosting.com
			NS2=ns45.wpxhosting.com
		elif [[ "$value" = "67.202.92.17" ]]; then
			NS1=ns40.wpxhosting.com
			NS2=ns41.wpxhosting.com
		elif [[ "$value" = "67.202.92.16" ]]; then
			NS1=ns38.wpxhosting.com
			NS2=ns39.wpxhosting.com
		elif [[ "$value" = "67.202.92.15" ]]; then
			NS1=ns34.wpxhosting.com
			NS2=ns35.wpxhosting.com
		elif [[ "$value" = "67.202.92.14" ]]; then
			NS1=ns32.wpxhosting.com
			NS2=ns33.wpxhosting.com
		elif [[ "$value" = "67.202.92.13" ]]; then
			NS1=ns30.wpxhosting.com
			NS2=ns31.wpxhosting.com
		elif [[ "$value" = "67.202.92.12" ]]; then
			NS1=ns26.wpxhosting.com
			NS2=ns27.wpxhosting.com
		elif [[ "$value" = "67.202.92.11" ]]; then
			NS1=ns24.wpxhosting.com
			NS2=ns25.wpxhosting.com
		elif [[ "$value" = "67.202.92.4" ]]; then
			NS1=ns9.wpxhosting.com
			NS2=ns10.wpxhosting.com
		elif [[ "$value" = "67.202.92.9" ]]; then
			NS1=ns22.wpxhosting.com
			NS2=ns23.wpxhosting.com
		elif [[ "$value" = "67.202.92.8" ]]; then
			NS1=ns20.wpxhosting.com
			NS2=ns21.wpxhosting.com
		elif [[ "$value" = "67.202.92.7" ]]; then 
			NS1=ns18.wpxhosting.com
			NS2=ns19.wpxhosting.com
		elif [[ "$value" = "5.254.55.38" ]]; then #uk5
			NS1=ns60.wpx.net
			NS2=ns61.wpx.net
		elif [[ "$value" = "5.254.55.37" ]]; then #uk4 
			NS1=ns54.wpxhosting.com
			NS2=ns55.wpxhosting.com
		elif [[ "$value" = "5.254.55.36" ]]; then #uk3 
			NS1=ns42.wpxhosting.com
			NS2=ns43.wpxhosting.com
		elif [[ "$value" = "5.254.55.35" ]]; then #uk2 
			NS1=ns36.wpxhosting.com
			NS2=ns37.wpxhosting.com
		elif [[ "$value" = "5.254.55.34" ]]; then #uk1
			NS1=ns28.wpxhosting.com
			NS2=ns29.wpxhosting.com
		elif [[ "$value" = "103.25.59.18" ]]; then #au1
			NS1=ns48.wpxhosting.com
			NS2=ns49.wpxhosting.com
		fi
		
	if curl --silent `wpx option get siteurl` >/dev/null 2>&1 ; then #checks the site for SSL
		wehave=sslon
	else
		echo "We have noticed that your site is using an SSL certificate. If you want us to move your current certificate please provide us with the certificate itself, its private key and its CA bundle.

If you are not familiar with those or your current certificate can't be moved from your old host, please get back to us once the propagation is completed and we will install one of our free SSL certificates."
	fi
	echo " "
	echo "The migration was completed successfully.

Now you can update your domain name servers or A records with:

A record's IP: $value
Nameserver 1: $NS1
Nameserver 2: $NS2

Keep in mind that our WPX Cloud is enabled by default for your website for better performance.
More information can be found here: https://kb.wpx.net/introducing-the-wpx-cloud-why-your-website-needs-it/
In order to experience the great speed of our WPX Cloud, you need to use our NS records to point the domain. (if you wish to point the domain with the IP records of the Cloud, please contact us for more information).

If you are unsure of exactly how to change your nameservers at your domain registrar (e.g. GoDaddy, Namecheap), please let us know and we will do that for you at no cost (logins required please!).

Keep in mind that the DNS propagation usually takes 24 hours. In some rare cases, it can take up to 48 hours.
You can monitor the progress of DNS propagation here: https://www.whatsmydns.net/
More information on the topic can be found here: https://kb.wpx.net/what-is-dns-propagation-and-why-can-it-take-up-to-48-hours-/"
		if [[ -d "./wp-content/plugins/w3-total-cache" ]]; then 
			echo "For better performance of your website, we have installed the W3 Total Cache plugin with our pre-configured settings which work best with our server's configuration as well as the Autoptimize plugin.

More information can be found here: https://kb.wpx.net/why-wpx-hosting-recommends-w3-total-cache/"
		fi
	echo " "
	echo "Migration notes "
	echo "---------------"

	if [[ -d "./wp-content/plugins/w3-total-cache" ]]; then 
		echo "W3TC/Autoptimize"
	fi
	if [[ -d "./wp-content/plugins/jetpack" ]]; then 
		echo "Jetpack"
	fi
	if [[ -d "./wp-content/plugins/wordfence" ]]; then 
		echo "Wordfence"
	fi
	if [[ -d "./wp-content/plugins/ewww-image-optimizer" ]]; then 
		echo "EWWW IO - phpexec on"
	fi
	if [[  "$wehave" = "sslon"  ]]; then
		echo "SSL migrated"
	else
		echo "SSL macro"
	fi
}

function allinone() {
	if [[ -f "wp-config.php" ]]; then #Checks if there is a website installed in that directory
		echo "Wordpress already installed!"
	elif [[ -f "index.php" ]]; then
		echo "Wordpress already installed!"
	else
		echo "No Wordpress detected! You need to install WP first!"
		echo " "
		freshwp
	fi
count=`ls -1 *.wpress 2>/dev/null | wc -l`
	if [[ $count != 0 ]]; then 
		echo " "
	else
		echo "Error! No '.wpress' backup detected. Please enter the URL below to download your backup."
		echo "Note: To make this work, you may need to disable the DNS zone in Virtual min or download the backup from another URL different than your domain."
		echo " "
		while true; do
			read -p "Backup URL: " backup_url
				if [[ "$backup_url" = "b" ]]; then
					mainmenu
				elif [[ -z "$backup_url" ]]; then
					continue
				fi
				if wget $backup_url; then
					echo "Download complete."
					not=fail
				else
					echo "Could not download All in one backup."
					allinone
				fi
			break
		done
	fi
	while true; do
		read -p "Is the website loading with www? [y/n]: " WWWW
			if [[  "$WWWW" = "y"  ]]; then
				wpx search-replace "http://" "http://www." --all-tables --quiet
				wpx search-replace "http:" "https:" --all-tables --quiet
			elif [[  "$WWWW" = "n"  ]]; then
				wpx search-replace "http:" "https:" --all-tables --quiet
			elif [[ "$WWWW" = "b" ]]; then
				mainmenu
			elif [[ -z $WWWW ]]; then
				echo "Error!"
				continue
			else
				echo "Error!"
				continue
			fi
		break
	done
	while true; do
		read -p "Delete All in one after migration? [y/n]: " delete_aio
			if [[ "$delete_aio" = "n" ]]; then
				echo "OK"
			elif [[ "$delete_aio" = "y" ]]; then
				echo "OK"			
			elif [[ "$delete_aio" = "b" ]]; then
				mainmenu
			else 
				echo "Error!"
				continue
			fi
		break
	done
	if wpx plugin install http://omg.doyouevencode-bro.cloud/all-in-one-wp-migration.zip --activate >/dev/null 2>&1; then
		echo "Done"
	else
		wpx plugin delete all-in-one-wp-migration --quiet >/dev/null 2>&1
		wpx plugin delete all-in-one-wp-migration-unlimited-extension --quiet >/dev/null 2>&1
		wpx plugin install http://omg.doyouevencode-bro.cloud/all-in-one-wp-migration.zip --quiet >/dev/null 2>&1
		wpx plugin activate all-in-one-wp-migration --quiet >/dev/null 2>&1
	fi
wpx ai1wm backup > temp.txt && rm temp.txt
cd wp-content/ai1wm-backups/
find . -type f -name "*.wpress" -exec rm {} +
cd ../../
wpx plugin delete hello --quiet
wpx plugin delete akismet --quiet
rm -rf wp-content/themes/*
find . -type f -name "*.wpress" -exec mv {} wpx-backup.wpress \;
	if [[ -f "wpx-backup.wpress" ]]; then
		find . -type f -name "*.wpress" -exec mv -t ./wp-content/ai1wm-backups/ {} +
	else
 		echo "Error!"
 		mainmenu
	fi
	if wpx ai1wm restore wpx-backup.wpress; then
		echo "Done"
	else
 		echo "Error!"
 		mainmenu
 	fi
echo "Fixing permissions..."
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +
find . -type f -name "*error_log*" -exec rm {} +
find . -type f -name ".listing*" -exec rm {} +
echo "Clearing cache and mu-plugins..."
tmp=$(mktemp)
	if [[ "$delete_aio" = "y" ]]; then
		wpx plugin delete all-in-one-wp-migration --quiet >/dev/null 2>&1
		wpx plugin delete all-in-one-wp-migration-unlimited-extension --quiet >/dev/null 2>&1
		rm -rf wp-content/ai1wm-backups
	elif [[ "$delete_aio" = "n" ]]; then
		wpx plugin update all-in-one-wp-migration --quiet >/dev/null 2>&1
	fi
}

function freshwp(){ #Install fresh Wordpress with the following domain/DBname/DBpass details.
while true; do
read -p "[c]ustom or [r]andom admin username & password? " creds
	if [[ "$creds" = "c" ]]; then
			read -p "Username: " username
				if [[ "$username" = "b" ]]; then
					mainmenu
				fi
			read -p "Password: " parola
				if [[ "$parola" = "b" ]]; then
					continue
				fi
			read -p "Email address: " mail
				if [[ "$mail" = "b" ]]; then
					continue
				fi
			break
	elif [[ "$creds" = "r" ]]; then
			parola=`date +%s | sha256sum | base64 | head -c 18 ;`
			username=wpx_$name
			mail=test@wpx.net
	elif [[ "$creds" = "b" ]]; then
			mainmenu
		else
			echo "Error! Please select a valid option."
			continue
		fi
	break
done
read -p "URL: " website_url
read -s -p "Enter password: " somepassword
mysql -u$USER -h localhost -p$somepassword -e 'show databases;'
read -p "Select database: " datadatabasesql
echo " "
cat <<EOT>> .htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
RewriteCond %{HTTPS} !=on [NC]
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>
EOT
wpx core download --force --quiet
echo "Success: WordPress downloaded."
wpx config create --dbname=$datadatabasesql --dbuser=$USER --dbpass=$somepassword --dbprefix=wp_ --quiet
echo "Success: Generated 'wp-config.php' file."
wpx core install --url=$website_url --title=Home --admin_user=$username --admin_password=$parola --admin_email=$mail --quiet
echo "Success: WordPress installed successfully."
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +
wpx search-replace "http:" "https:" --all-tables --quiet
wpx cache flush --quiet
pkill -u$USER php
echo " "
echo "Admin details: "
echo "Login: $URL/wp-login.php"
echo "Username: $username"
echo "Password: $parola"
echo "Email: $mail"
echo " "
echo "Done"
}

function wpe() {
read -p "Backup URL: " WPEURL
read -p "Enter password: " wpedbparola
mysql -u$USER -h localhost -p$wpedbparola -e 'show databases;'
read -p "Select database: " wpedbname
wget $WPEURL
check_for_files
unzip -q $backupfile
wpeprefix=`cat wp-config.php | grep table_prefix | cut -c 18- | rev | cut -c 3- | rev`
wpecname=`grep PWP_NAME wp-config.php | cut -c 22- | rev | cut -c 5- | rev`
old_path=`grep -Eo "\/(home|home\d|home\d\d|nas|var|html|root|www|httpdocs)\/.*\/wp-content\/" wp-content/mysql.sql | sed -e 's/ *$//' | tr ',' '\n' | tr ';' '\n' | tr ':' '\n' | tr '"' '\n' | tr '%' '\n' | grep -E "\/(home|home\d|home\d\d|nas|var|html|root|www|httpdocs)\/.*\/wp-content\/" | sort -nu | rev | sed -e 's+.*tnetnoc-pw\/++g' | rev`
echo "Old path: $old_path"
echo "New path: `pwd`"
rm wp-config.php
wpx config create --dbname=$wpedbname --dbuser=$USER --dbpass=$wpedbparola --dbprefix=$wpeprefix --quiet
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +
find . -type f -name ".listing*" -exec rm {} +
find . -type f -name "*error_log*" -exec rm {} +
wpx db import wp-content/mysql.sql
wpx search-replace $old_path `pwd` --all-tables --quiet
echo "Success: DB paths replaced."
wpx search-replace $wpecname.wpengine.com `wpx option get siteurl | cut -c 9-` --all-tables --quiet
}

function bai() {
echo " "
echo "Bye"
rm ./migrator.sh
exit
}

sleep 1
echo ""
echo "Hi!"
sleep 2
echo "This is the WPX migrator! It's designed to make things easy for you and doesn't require much to do from you."
sleep 1
mainmenu