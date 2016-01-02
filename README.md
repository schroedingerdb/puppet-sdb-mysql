# sdb_mysql

#### Table of Contents

1. [Module Description](#module-description)
2. [Setup](#setup)

## Module Description

The sdb_mysql module installs, configures, and manages multiple MySQL instances. 
It requires the module [puppetlabs/mysql](https://forge.puppetlabs.com/puppetlabs/mysql),
please install the puppetlabs/mysql module before using sdb_mysql module.
```sh
sudo puppet module install puppetlabs-mysql
```
The code structure is very similar to puppetlabs/mysql and the goal is to reuse all parameters of puppetlabs/mysql.

## Setup
### Module installation
Install sdb_mysql module on your system.
```sh
sudo git clone https://github.com/schroedingerdb/puppet-sdb_mysql.git /etc/puppet/modules/sdb_mysql
```

### Beginning with sdb_mysql

The behavior of the module is similar to [puppetlabs/mysql](https://forge.puppetlabs.com/puppetlabs/mysql). Read the documentation of puppetlabs/mysql for details.
If you want to install multiple MySQL instances you can do this:

```puppet
$root_password = "root"

$override_options = {
  'mysqld' => {
    'bind-address' => '0.0.0.0',
  }
}

class { 'mysql::server':
  root_password => $root_password,
  override_options => $override_options
}

class { 'sdb_mysql':;}

sdb_mysql::instance {
  'mysql-1': port => 3307, override_options => $override_options ;
  'mysql-2': port => 3308, override_options => $override_options ;
  'mysql-3': port => 3309, override_options => $override_options ;
}
```
With this example you will install one *normal* mysql server instance on port 3306 and three multiple instances on other ports.

### Stop and start services

After running puppet with the example above you can stop and start service as usual.
```sh
sudo service mysql stop
sudo service mysql-1 stop
sudo service mysql-2 stop
sudo service mysql-3 stop

sudo service mysql start
sudo service mysql-1 start
sudo service mysql-2 start
sudo service mysql-3 start
```

###Config, data and log folder
With the example above these folder exists.
```
/etc/mysql/
/etc/mysql-1/
..
/var/lib/mysql/
/var/lib/mysql-1/
..
/var/log/mysql/
/var/log/mysql-1/
```
