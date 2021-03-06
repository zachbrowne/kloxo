<?php
$altconf = "/opt/configs/lighttpd/conf/customs/{$domainname}.conf";

if (file_exists($altconf)) {
	print("## MR - Use '{$altconf}' instead this file");
	return;
}
?>
### begin - web of '<?= $domainname; ?>' - do not remove/modify this line

<?php

$altconf = "/opt/configs/lighttpd/conf/customs/{$domainname}.conf";

if (file_exists($altconf)) {
	print("## MR - Use {$altconf} instead this file");
	return;
}

$webdocroot = $rootpath;

if (!isset($phpselected)) {
	$phpselected = 'php';
}

if (!isset($timeout)) {
	$timeout = '300';
}

if (($webcache === 'none') || (!$webcache)) {
	$ports[] = '80';
	$ports[] = '443';
} else {
	$ports[] = '8080';
	$ports[] = '8443';
}

foreach ($certnamelist as $ip => $certname) {
	$cert_ip = $ip;

	$sslpath = "/home/kloxo/ssl";

	if (file_exists("{$sslpath}/{$domainname}.key")) {
		$cert_file = "{$sslpath}/{$domainname}";
	} else {
		$cert_file = "{$sslpath}/{$certname}";
	}

}

$statsapp = $stats['app'];
$statsprotect = ($stats['protect']) ? true : false;

$tmpdom = str_replace(".", "\.", $domainname);

$excludedomains = array("cp", "webmail");

$excludealias = implode("|", $excludedomains);

$serveralias = '';

if ($wildcards) {
	$serveralias .= "(?:^|\.){$tmpdom}$";
} else {
	if ($wwwredirect) {
		$serveralias .= "^(?:www\.){$tmpdom}$";
	} else {
		$serveralias .= "^(?:www\.|){$tmpdom}$";
	}
}

if ($serveraliases) {
	foreach ($serveraliases as &$sa) {
		$tmpdom = str_replace(".", "\.", $sa);
		$serveralias .= "|^(?:www\.|){$tmpdom}$";
	}
}

if ($parkdomains) {
	foreach ($parkdomains as $pk) {
		$pa = $pk['parkdomain'];
		$tmpdom = str_replace(".", "\.", $pa);
		$serveralias .= "|^(?:www\.|){$tmpdom}$";
	}
}

if ($webmailapp) {
	if ($webmailapp === '--Disabled--') {
		$webmaildocroot = "/home/kloxo/httpd/disable";
	} else {
		$webmaildocroot = "/home/kloxo/httpd/webmail/{$webmailapp}";
	}
} else {
	$webmaildocroot = "/home/kloxo/httpd/webmail";
}

$webmailremote = str_replace("http://", "", $webmailremote);
$webmailremote = str_replace("https://", "", $webmailremote);

if ($indexorder) {
	$indexorder = implode(' ', $indexorder);
}

$indexorder = '"' . $indexorder . '"';
$indexorder = str_replace(' ', '", "', $indexorder);

if ($blockips) {
	$biptemp = array();
	foreach ($blockips as &$bip) {
		if (strpos($bip, ".*.*.*") !== false) {
			$bip = str_replace(".*.*.*", ".0.0/8", $bip);
		}
		if (strpos($bip, ".*.*") !== false) {
			$bip = str_replace(".*.*", ".0.0/16", $bip);
		}
		if (strpos($bip, ".*") !== false) {
			$bip = str_replace(".*", ".0/24", $bip);
		}
		$biptemp[] = $bip;
	}
	$blockips = $biptemp;

	$blockips = implode('|', $blockips);
}

$userinfo = posix_getpwnam($user);

if ($userinfo) {
	$fpmport = (50000 + $userinfo['uid']);
} else {
	return false;
}

// MR -- for future purpose, apache user have uid 50000
// $userinfoapache = posix_getpwnam('apache');
// $fpmportapache = (50000 + $userinfoapache['uid']);
$fpmportapache = 50000;

if ($reverseproxy) {
	$lighttpdextratext = null;
}

$disabledocroot = "/home/kloxo/httpd/disable";
$cpdocroot = "/home/kloxo/httpd/cp";

$globalspath = "/opt/configs/lighttpd/conf/globals";

if (file_exists("{$globalspath}/custom.generic.conf")) {
	$generic = "custom.generic";
} else {
	$generic = "generic";
}

if (file_exists("{$globalspath}/custom.header_base.conf")) {
	$header_base = "custom.header_base";
} else if (file_exists("{$globalspath}/header_base.conf")) {
	$header_base = "header_base";
}

if (file_exists("{$globalspath}/custom.header_ssl.conf")) {
	$header_ssl = "custom.header_ssl";
} else if (file_exists("{$globalspath}/header_ssl.conf")) {
	$header_ssl = "header_ssl";
}

if ($disabled) {
	$sockuser = 'apache';
} else {
	$sockuser = $user;
}

if ($disabled) {
	$cpdocroot = $webmaildocroot = $webdocroot = $disabledocroot;
}

?>

## cp for '<?=$domainname;?>'
$HTTP["host"] =~ "^cp\.<?=str_replace(".", "\.", $domainname);?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	var.user = "apache"
	var.fpmport = "<?=$fpmportapache;?>"
	var.rootdir = "<?=$cpdocroot;?>/"
	var.phpselected = "php"
	var.timeout = "<?=$timeout;?>"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )

	include "<?=$globalspath;?>/switch_standard.conf"

}

<?php
if ($webmailremote) {
?>

## webmail for '<?=$domainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $domainname);?>" {

	url.redirect = ( "/" =>  "http://<?=$webmailremote;?>/" )

}

<?php
} else {
?>

## webmail for '<?=$domainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $domainname);?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	var.user = "apache"
	var.fpmport = "<?=$fpmportapache;?>"
	var.rootdir = "<?=$webmaildocroot;?>/"
	var.phpselected = "php"
	var.timeout = "<?=$timeout;?>"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )

	include "<?=$globalspath;?>/switch_standard.conf"

}

<?php
}

if ($domainredirect) {
	foreach ($domainredirect as $domredir) {
		$redirdomainname = $domredir['redirdomain'];
		$redirpath = ($domredir['redirpath']) ? $domredir['redirpath'] : null;
		$webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

		if ($redirpath) {
			if ($disabled) {
			 	$$redirfullpath = $disablepath;
		 	} else {
				$redirfullpath = str_replace('//', '/', $webdocroot . '/' . $redirpath);
			}
?>

## web for redirect '<?=$redirdomainname;?>'
$HTTP["host"] =~ "^<?=str_replace(".", "\.", $redirdomainname);?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	$HTTP["scheme"] == "https" {
		include "/opt/configs/lighttpd/conf/globals/header_ssl.conf"
	}

	var.user = "<?=$sockuser;?>"
	var.fpmport = "<?=$fpmport;?>"
	var.rootdir = "<?=$redirfullpath;?>/"
	var.phpselected = "<?=$phpselected;?>"
	var.timeout = "<?=$timeout;?>"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )
<?php

			if ($enablephp) {
?>

	include "<?=$globalspath;?>/switch_standard.conf"
<?php
			}
?>

}

<?php
		} else {
			if ($disabled) {
				$$redirfullpath = $disablepath;
			} else {
				$redirfullpath = $webdocroot;
			}
?>

## web for redirect '<?=$redirdomainname;?>'
$HTTP["host"] =~ "^<?=str_replace(".", "\.", $redirdomainname);?>" {

	server.follow-symlink = "disable"

	var.rootdir = "<?=$redirfullpath;?>/"

	server.document-root = var.rootdir

	url.redirect = ( "/" =>  "http://<?=$domainname;?>/" )

}

<?php
		}
	}
}

if ($parkdomains) {
	foreach ($parkdomains as $dompark) {
		$parkdomainname = $dompark['parkdomain'];
		$webmailmap = ($dompark['mailflag'] === 'on') ? true : false;

		if ($webmailremote) {
?>

## webmail for parked '<?=$parkdomainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $parkdomainname);?>" {

	server.follow-symlink = "disable"

	url.redirect = ( "/" =>  "http://<?=$webmailremote;?>/" )

}

<?php

		} elseif ($webmailmap) {
			if ($webmailapp) {
?>

## webmail for parked '<?=$parkdomainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $parkdomainname);?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	var.user = "apache"
	var.fpmport = "<?=$fpmportapache;?>"
	var.rootdir = "<?=$webmaildocroot;?>/"
	var.phpselected = "php"
	var.timeout = "<?=$timeout;?>"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )

	include "<?=$globalspath;?>/switch_standard.conf"

}

<?php
   			 }
   		 } else {
?>

## No mail map for parked '<?=$parkdomainname;?>'

<?php
		}
	}
}

if ($domainredirect) {
	foreach ($domainredirect as $domredir) {
		$redirdomainname = $domredir['redirdomain'];
		$webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

		if ($webmailremote) {
?>

## webmail for redirect '<?=$redirdomainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $redirdomainname);?>" {

	server.follow-symlink = "disable"

	url.redirect = ( "/" =>  "http://<?=$webmailremote;?>/" )

}

<?php
		} elseif ($webmailmap) {
			if ($webmailapp) {
?>

## webmail for redirect '<?=$redirdomainname;?>'
$HTTP["host"] =~ "^webmail\.<?=str_replace(".", "\.", $redirdomainname);?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	var.user = "apache"
	var.fpmport = "<?=$fpmportapache;?>"
	var.rootdir = "<?=$webmaildocroot;?>/"
	var.phpselected = "php"
	var.timeout = "<?=$timeout;?>"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )

	include "<?=$globalspath;?>/switch_standard.conf"

}

<?php
			}
		} else {
?>

## No mail map for redirect '<?=$redirdomainname;?>'

<?php
		}
	}
}

if ($ip !== '*') {
	$ipssl = "|" . $ip;
} else {
	$ipssl = "";
}

if ($wwwredirect) {
?>

## web for '<?=$domainname;?>'
$HTTP["host"] =~ "<?=$domainname;?><?=$ipssl;?>" {

	server.follow-symlink = "disable"

	url.redirect = ( "^/(.*)" => "http://www.<?=$domainname;?>/$1" )
}


## web for '<?=$domainname;?>'
$HTTP["host"] =~ "<?=$serveralias;?><?=$ipssl;?>" {

	server.follow-symlink = "disable"
<?php
} else {
?>

## web for '<?=$domainname;?>'
$HTTP["host"] =~ "<?=$serveralias;?><?=$ipssl;?>" {

	server.follow-symlink = "disable"

	include "<?=$globalspath;?>/acme-challenge.conf"

	include "<?=$globalspath;?>/<?=$header_base;?>.conf"

	$HTTP["scheme"] == "https" {
		include "/opt/configs/lighttpd/conf/globals/header_ssl.conf"
	}
<?php
}
?>

	var.domain = "<?=$domainname;?>"
	var.user = "<?=$sockuser;?>"
	var.fpmport = "<?=$fpmport;?>"
	var.phpselected = "<?=$phpselected;?>"
	var.timeout = "<?=$timeout;?>"

	var.rootdir = "<?=$webdocroot;?>/"

	server.document-root = var.rootdir

	index-file.names = ( <?=$indexorder;?> )
<?php
if ($redirectionlocal) {
	foreach ($redirectionlocal as $rl) {
?>

	alias.url  += ( "<?=$rl[0];?>/" => "$rootdir<?=str_replace("//", "/", $rl[1]);?>" )
<?php
	}
}

if ($redirectionremote) {
	foreach ($redirectionremote as $rr) {
		if ($rr[0] === '/') {
			$rr[0] = '';
		}

		if ($rr[2] === 'both') {
?>

	url.redirect += ( "^(<?=$rr[0];?>/|<?=$rr[0];?>$)" => "http://<?=$rr[1];?>" )
<?php
		} else {
			$protocol2 = ($rr[2] === 'https') ? "https://" : "http://";
?>

	url.redirect += ( "^(/<?=$rr[0];?>/|/<?=$rr[0];?>$)" => "<?=$protocol2;?><?=$rr[1];?>" )
<?php
		}
	}
}

if ($enablestats) {
?>

	include "<?=$globalspath;?>/stats_log.conf"
<?php
//	if ((!$reverseproxy) || (($reverseproxy) && ($webselected === 'front-end'))) {
?>

	include "<?=$globalspath;?>/stats.conf"
<?php
		if ($statsprotect) {
?>

	include "<?=$globalspath;?>/dirprotect_stats.conf"
<?php
		}
//	}
}

	if ($lighttpdextratext) {
?>

	# Extra Tags - begin
<?=$lighttpdextratext;?>

	# Extra Tags - end
<?php
	}

	if ((!$reverseproxy) && (file_exists("{$globalspath}/{$domainname}.conf"))) {
		if ($enablephp) {
?>

	include "<?=$globalspath;?>/<?=$domainname;?>.conf"
<?php
		}
	} else {
		if (($reverseproxy) && ($webselected === 'front-end')) {
			if ($enablephp) {
?>

	include "<?=$globalspath;?>/php-fpm_standard.conf"
<?php
			}
		} else {
?>

	include "<?=$globalspath;?>/switch_standard.conf"
<?php
		}
	}

	if (!$reverseproxy) {
		if ($dirprotect) {
			foreach ($dirprotect as $k) {
				$protectpath = $k['path'];
				$protectauthname = $k['authname'];
				$protectfile = str_replace('/', '_', $protectpath) . '_';
?>

	$HTTP["url"] =~ "^/<?=$protectpath;?>[/$]" {
		auth.backend = "htpasswd"
		auth.backend.htpasswd.userfile = "/home/httpd/" + var.domain + "/__dirprotect/<?=$protectfile;?>"
		auth.require = ( "/<?=$protectpath;?>" => (
		"method" => "basic",
		"realm" => "<?=$protectauthname;?>",
		"require" => "valid-user"
		))
	}
<?php
			}
		}
	}

	if ($blockips) {
?>

	$HTTP["remoteip"] =~ "{<?=$blockips;?>}" {
		url.access-deny = ( "" )
	}
<?php
	}
?>

	var.kloxoportssl = "<?=$kloxoportssl;?>"
	var.kloxoportnonssl = "<?=$kloxoportnonssl;?>"

	include "<?=$globalspath;?>/<?=$generic;?>.conf"

	alias.url += ( "/" => var.rootdir )
<?php
	if ($enablecgi) {
?>

	$HTTP["url"] =~ "^/cgi-bin" {
		#cgi.assign = ( "" => "/home/httpd/" + var.domain + "/perlsuexec.sh" )
		cgi.assign = ( "" => "/usr/bin/perl" )
	}
<?php
	}
?>

	$HTTP["url"] =~ "^/" {
<?php
	if ($enablecgi) {
?>
		#cgi.assign = ( ".pl" => "/home/httpd/" + var.domain + "/perlsuexec.sh" )
		cgi.assign = ( ".pl" => "/usr/bin/perl" )
<?php
	}

	if ($dirindex) {
?>
		dir-listing.activate = "enable"
<?php
	}
?>

		## trick using 'microcache' not work; no different performance!
		#expire.url = ( "" => "access 10 seconds" )
	}

}


### end - web of '<?=$domainname;?>' - do not remove/modify this line
