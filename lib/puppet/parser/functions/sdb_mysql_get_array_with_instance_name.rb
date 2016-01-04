module Puppet::Parser::Functions
  newfunction(:sdb_mysql_get_array_with_instance_name, :type => :rvalue) do |args|
    
    raise(Puppet::ParseError, "sdb_mysql_get_array_with_instance_name(): Wrong number of arguments " +
      "given (#{args.size} for 2)") if args.size < 2
    
    new_users = {}

    if args[0].is_a?(Hash)

      args[0].each do |key, value|
        new_users[args[1]+ " " + key] = value
        new_users[args[1]+ " " + key]['instance_name'] = args[1]
        new_users[args[1]+ " " + key]['defaults_file'] = "/etc/" + args[1] + "/my.cnf"
        
        # if user key exists then it is a grants hash
        if ! value.has_key?("user")
          new_users[args[1]+ " " + key]['user_host'] = key
        end
        
      end
    end
    
    return new_users
  end
end