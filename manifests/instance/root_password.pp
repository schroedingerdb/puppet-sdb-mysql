#
define sdb_mysql::instance::root_password (
  $instance_name = undef,
  $defaults_file = undef,
  $port = undef,
  $socket = undef
) {
  
  $my_cnf = "${::root_home}/.my.cnf.${instance_name}"

  exec { "${instance_name}_remove_install_pass":
    command => "/usr/bin/mysqladmin --defaults-file=${defaults_file} -u root password ''",
    unless  => "/usr/bin/mysql --defaults-file=${defaults_file} --user=root --password=${mysql::server::root_password} -e 'exit'",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    require => Service["${instance_name}"]
  }
  ->
  exec { "${instance_name}_remove_my_cnf":
    command => "test -e ${my_cnf} && rm ${my_cnf}; exit 0",
    unless  => "/usr/bin/mysql --defaults-file=${defaults_file} --user=root --password=${mysql::server::root_password} -e 'exit'",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
  }

  #manage root password if it is set
  if $mysql::server::create_root_user == true and $mysql::server::root_password != 'UNSET' {
    sdb_mysql_user { "${instance_name} root@localhost":
      instance_name => $instance_name,
      defaults_file => $defaults_file,
      user_host => 'root@localhost',
      ensure        => present,
      password_hash => mysql_password($mysql::server::root_password),
      require       => Exec["${instance_name}_remove_my_cnf"]
    }
  }

  if $mysql::server::create_root_my_cnf == true and $mysql::server::root_password != 'UNSET' {
    file { "$my_cnf":
      content => template('sdb_mysql/my.cnf.pass.erb'),
      owner   => 'root',
      mode    => '0600',
    }

    # show_diff was added with puppet 3.0
    if versioncmp($::puppetversion, '3.0') <= 0 {
      File["${::root_home}/.my.cnf"] { show_diff => false }
    }
    if $mysql::server::create_root_user == true {
      Sdb_mysql_user["${instance_name} root@localhost"] -> File["$my_cnf"]
    }
  }

}
