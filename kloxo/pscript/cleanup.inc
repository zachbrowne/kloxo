#!/bin/sh

if [ "$(dir -l /usr/bin/lxphp.exe|grep 'php-cli.sh')" == "" ] ; then
	echo
	echo "* No 'lxphp.exe' exists"
	echo "  - Need install Kloxo-MR 7.0 perfectly with 'sh /script/upcp -y'"
	echo
	exit
fi

. /script/fix-urgent

. /script/counter-start.inc

t=$(mysql -V|awk '{print $5}'|grep -i '5.0.')

if [ "$t" != "" ] ; then
	echo "Need update mysql first..."
	echo "- Run 'yum replace mysql --replace-with=mysql55'" 
	echo "- For OpenVZ VPS, add 'innodb_use_native_aio=0' under '[mysqld]' in '/etc/my.cnf'"
	exit
fi

chkconfig kloxo on

for i in $(ls -ld /opt/php* | awk '{print $9}' | sed 's:/opt/::g' | tr '\n' ' ') ; do
	if [ "$(readlink /usr/bin/${i}-cli)" == "/opt/${i}/custom/${i}-cli.sh" ] ; then
		sh /script/phpm-installer $i -y
	fi
done

sh /script/fixlxphpexe

## MR -- no need always use 'fpm' mode
#sh /script/set-kloxo-php

. /script/directory
	
if [ "${1}" == "simple" ] ; then
	lxphp.exe ../bin/common/cleanup.php --without-services
else
	lxphp.exe ../bin/common/cleanup.php
fi

echo
echo "*** Restart services - BEGIN ***"
if [ "${1}" == "nokloxorestart" ] ; then
	sh /script/restart-all --force
else
	sh /script/restart-services --force
fi
echo "*** Restart services - END ***"
echo

. /script/counter-end.inc

