define sdb_mysql::instance::deinstall (
)
{
  $mysqld_name = "${name}d"
  
  $folder = [
    "/etc/init.d/${name}",
    "/etc/${name}",
    "/var/log/${name}",
    "/var/run/${mysqld_name}",
    "/var/lib/${name}",
    "/root/.my.cnf.${name}"
  ]
  
  exec { "${name}_stop_service":
    command => "/usr/sbin/service ${name} stop; exit 0",
    onlyif => "/usr/bin/test -e /etc/init.d/${name}"
  }
  ->
  file { $folder:
    ensure => absent,
    force => true
  }

  if $name == "mysql"
  {
    file { ["/root/.my.cnf"]:
      ensure => absent,
      force => true
    }
  }
}
