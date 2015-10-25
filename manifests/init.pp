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
  $apparmor_purged = true
) {

  if $apparmor_purged
  {
    package {
      'apparmor':
        ensure => purged
    }
  }
}
