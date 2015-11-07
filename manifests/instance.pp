define sdb_mysql::instance (
  $port = undef,
  $override_options = {}
){
  
  $mysqld_name = "${name}d"
  
  if $name != "mysql"
  {
    
    exec {
    "${name}_copy_init.d_script":
      command => "/bin/cp /etc/init.d/mysql /etc/init.d/${name}",
      creates => "/etc/init.d/${name}"
    }
    ->
    file_line { "${name}_init.d_script_replace_etc":
      path => "/etc/init.d/${name}",
      line => "CONF=/etc/${name}/my.cnf",
      match   => "CONF=/etc/mysql/my.cnf"
    }
    ->
    file_line { "${name}_init.d_script_replace_init.d":
      path => "/etc/init.d/${name}",
      line => "MYADMIN=\"/usr/bin/mysqladmin --defaults-file=/etc/${name}/debian.cnf\"",
      match   => "MYADMIN=\"/usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf\"",
    }
    ->
    file_line { "${name}_init.d_script_replace_mysqld_safe":
      path => "/etc/init.d/${name}",
      line => "/usr/bin/mysqld_safe --defaults-file=/etc/${name}/my.cnf > /dev/null 2>&1 &",
      match   => "/usr/bin/mysqld_safe > /dev/null 2>&1 &",
    }
    ->
    file_line { "${name}_init.d_script_var_run_folder":
      path => "/etc/init.d/${name}",
      line => "test -e /var/run/${mysqld_name} || install -m 755 -o mysql -g root -d /var/run/${mysqld_name}",
      match   => 'test -e /var/run/mysqld \|| install -m 755 -o mysql -g root -d /var/run/mysqld',
    }

		$instance_options = {
		  'mysqld' => {
		    'port' => $port,
		    'datadir' => "/var/lib/${name}",
        'log-error' => "/var/log/${name}/error.log",
        'pid-file' => "/var/run/${mysqld_name}/mysqld.pid",
        'socket' => "/var/run/${mysqld_name}/mysqld.sock",
				'ssl-ca' => "/etc/${name}/cacert.pem",
				'ssl-cert' => "/etc/${name}/server-cert.pem",
				'ssl-key' => "/etc/${name}/server-key.pem",
        'tmpdir' => "/tmp/${name}"
		  },
		  'mysqld_safe' => {
		    'log-error' => "/var/log/${name}/error.log",
        'socket' => "/var/run/${mysqld_name}/mysqld.sock"
		  },
		  'client' => {
		    'socket' => "/var/run/${mysqld_name}/mysqld.sock",
        'port' => $port
		   }
		}
    
    $default_options = mysql_deepmerge($mysql::params::default_options, $instance_options)
    $options = mysql_deepmerge($default_options, $override_options)
    
    exec {
    "${name}_copy_folder_etc_mysql":
      command => "/bin/cp -r /etc/mysql /etc/${name}",
      creates => "/etc/${name}"
    }
    ->
    file_line { "${name}_etc_debian.cnf":
      path => "/etc/${name}/debian.cnf",
      line => "socket   = /var/run/${mysqld_name}/mysqld.sock",
      match   => "socket   = /var/run/mysqld/mysqld.sock",
      multiple => true
    }
    ->
    file { "${name}-mysql-config-file":
      path                    => "/etc/${name}/my.cnf",
      content                 => template('mysql/my.cnf.erb'),
      mode                    => '0644',
      selinux_ignore_defaults => true,
    }
    ->
    exec {
    "${name}_replace_debian-start":
      command => "/bin/sed -i 's/\\/etc\\/mysql\\//\\/etc\\/${name}\\//g' /etc/${name}/debian-start",
      onlyif => "/bin/grep '/etc/mysql/' /etc/${name}/debian-start"
    }
    
    file { "/var/log/${name}":
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    
    file { $options['mysqld']['tmpdir']:
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    
    file { "/var/run/$mysqld_name":
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => 'root',
    }
    
    exec {
      "${name}-setup-mysql-data":
        command => "/usr/bin/mysql_install_db --defaults-file=/etc/${name}/my.cnf",
        require => File["${name}-mysql-config-file","/var/run/$mysqld_name"],
        creates => $options['mysqld']['datadir']
    }
    
  }
  else
  {
    warning("mysql instance name: ${name} is not allowed")
  }
}
