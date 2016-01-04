define sdb_mysql::instance (
  $port,
  $override_options = {},
  $users = {},
  $grants = {}
){

  # ensure that a mysql server is installed before installing instances
  Class['mysql::server']->Class['sdb_mysql'] -> Sdb_mysql::Instance[$name]

# TODO service mysql shutdown doesn't work
# TODO change root password

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
    ->
    file_line { "${name}_init.d_script_mysqld":
      path => "/etc/init.d/${name}",
      line => "/usr/sbin/mysqld --defaults-file=/etc/${name}/debian.cnf --print-defaults \\",
      match   => '/usr/sbin/mysqld --print-defaults \\',
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
        'tmpdir' => "/var/lib/${name}-tmp"
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

    File_line[ "${name}_init.d_script_var_run_folder" ] -> Exec["${name}_copy_folder_etc_mysql"]
    
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
    file { "/etc/${name}/my.cnf":
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
    ->
    file { "/var/log/${name}":
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    ->
    file { $options['mysqld']['tmpdir']:
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    ->
    file { "/var/run/$mysqld_name":
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => 'root',
    }
    
    # create mysql data folder
    exec { "${name}_setup_mysql_data":
      command => "/usr/bin/mysql_install_db --defaults-file=/etc/${name}/my.cnf",
      require => File["/etc/${name}/my.cnf","/var/run/$mysqld_name"],
      creates => $options['mysqld']['datadir']
    }
    ->
	  service { "${name}":
	    ensure   => true,
	    enable => true
	  }
    
    sdb_mysql::instance::root_password {
      "${name} root_password":
        instance_name => $name,
        defaults_file => "/etc/${name}/my.cnf",
        port => $port,
        socket => $options['client']['socket']
    }

    $debian_pw = $::sdb_mysql_get_debian_pw
    $new_users = sdb_mysql_get_array_with_instance_name($users,$name)
    $new_grants = sdb_mysql_get_array_with_instance_name($grants,$name)
    
    sdb_mysql_user { "${name} debian-sys-maint@localhost":
      instance_name => $name,
      defaults_file => "/etc/${name}/my.cnf",
      user_host => 'debian-sys-maint@localhost',
      ensure        => present,
      password_hash => mysql_password($debian_pw),
      require       => [ Sdb_mysql::Instance::Root_password["${name} root_password"], Service["${name}"] ]
    }
    ->
    sdb_mysql_grant { "${name} debian-sys-maint@localhost/*.*":
      instance_name => $name,
      defaults_file => "/etc/${name}/my.cnf",
	    ensure     => 'present',
	    options    => ['GRANT'],
	    privileges => ['ALL'],
	    table      => '*.*',
	    user       => 'debian-sys-maint@localhost'
    }
    
    create_resources('sdb_mysql_user', $new_users)
    create_resources('sdb_mysql_grant', $new_grants)
  }
  else
  {
    warning("mysql instance name '${name}' is not allowed")
  }
}
