class Puppet::Provider::Sdb_Mysql < Puppet::Provider

  # Without initvars commands won't work.
  initvars
  commands :mysql      => 'mysql'
  commands :mysqladmin => 'mysqladmin'
  # Optional defaults file
  def self.defaults_file(instance_name, defaults_file)
    return_value = "--defaults-file="+ defaults_file

    if File.file?("#{Facter.value(:root_home)}/.my.cnf." + instance_name)
      return_value = "--defaults-file=#{Facter.value(:root_home)}/.my.cnf." + instance_name
    end

    return return_value
  end
  
  def self.is_defaults_file_with_root_pw(instance_name)
    File.file?("#{Facter.value(:root_home)}/.my.cnf." + instance_name)
  end

  def self.users(instance_name, defaults_file)
    puts "self.users" + instance_name
    mysql([defaults_file(instance_name, defaults_file), '-NBe', "SELECT CONCAT(User, '@',Host) AS User FROM mysql.user"].compact).split("\n")
  end

  # Take root@localhost and munge it to 'root'@'localhost'
  def self.cmd_user(user)
    "'#{user.sub('@', "'@'")}'"
  end

  # Take root.* and return ON `root`.*
  def self.cmd_table(table)
    table_string = ''

    # We can't escape *.* so special case this.
    if table == '*.*'
      table_string << '*.*'
      # Special case also for PROCEDURES
    elsif table.start_with?('PROCEDURE ')
      table_string << table.sub(/^PROCEDURE (.*)(\..*)/, 'PROCEDURE `\1`\2')
    else
      table_string << table.sub(/^(.*)(\..*)/, '`\1`\2')
    end
    table_string
  end

  def self.cmd_privs(privileges)
    if privileges.include?('ALL')
      return 'ALL PRIVILEGES'
    else
      priv_string = ''
      privileges.each do |priv|
        priv_string << "#{priv}, "
      end
    end
    # Remove trailing , from the last element.
    priv_string.sub(/, $/, '')
  end

  # Take in potential options and build up a query string with them.
  def self.cmd_options(options)
    option_string = ''
    options.each do |opt|
      if opt == 'GRANT'
        option_string << ' WITH GRANT OPTION'
      end
    end
    option_string
  end

end
