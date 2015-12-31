# sdb_mysql

#### Table of Contents

1. [Module Description](#module-description)

## Module Description

The sdb_mysql module installs, configures, and manages the MySQL instances. It requires the module [puppetlabs/mysql](https://forge.puppetlabs.com/puppetlabs/mysql).
Install the puppetlabs/mysql module before using sdb_mysql module.
The code structure is very similar to puppetlabs/mysql and the goal is to reuse all parameters of puppetlabs/mysql.

## Setup

### Beginning with sdb_mysql

The behavior of the module is similar to [puppetlabs/mysql](https://forge.puppetlabs.com/puppetlabs/mysql).
Read the documentation of puppetlabs/mysql for details,

If you want to install 3 instance you can do this:

~~~
$root_password = "root"

$override_options = {
  'mysqld' => {
    'bind-address' => '0.0.0.0',
  }
}

class { 'mysql::server':
  root_password => $root_password,
  override_options => $override_options,
  users => $users,
  grants => $grants
}

class { 'sdb_mysql':;}

sdb_mysql::instance {
  'mysql-1': port => 3307, override_options => $override_options ;
  'mysql-2': port => 3308, override_options => $override_options ;
  'mysql-3': port => 3309, override_options => $override_options ;
}
~~~