Facter.add("sdb_mysql_get_debian_pw") do
  setcode do
    Facter::Util::Resolution.exec('grep "password" /etc/mysql/debian.cnf | sort -u | awk \'{ print $3 }\'')
  end
end
