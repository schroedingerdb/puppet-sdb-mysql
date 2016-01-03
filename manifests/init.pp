# Class: sdb_mysql
#
# This module manages sdb_mysql
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class sdb_mysql (
  $stop_appammor_service = true
){
  
  if $stop_appammor_service == true
  {
    # stopping appammor for mysql_install_db
    # details: http://schroedingerdb.com/mysql-en/installation-en/mysqld
    exec { "stopping_appammor":
      command => "sudo service apparmor teardown",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
      onlyif => "service apparmor status"
    }
  }

  # workaround for mysql 5.6 installation
  # http://schroedingerdb.com/mysql-en/installation-en/mysql_install_db
  exec { "create_file_my-default.cnf":
    command => "cp /etc/mysql/my.cnf /usr/share/mysql/my-default.cnf",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    creates => "/usr/share/mysql/my-default.cnf"
  }

}
