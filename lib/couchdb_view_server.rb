%w{"design", "view"}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }

commands_for :view_server do |command|
  begin
    cmd = command.shift
    case cmd
    when 'reset'
      View.reset
      return true 
    when 'ddoc'
      switch_state :design_document
    when 'add_fun'
      View.add_map_function(command.shift)
    when 'map_doc'
      View.new.map(command.shift)
    when 'reduce'
      View.new.reduce(command.shift, command.shift)
    when 'rereduce'
      View.new.rereduce(command.shift, command.shift)
    else
      throw :fatal, "error", "unknown command #{command}" 
    end
  rescue => e
    error e.message 
    error e.backtrace 
  end
end

commands_for :design_document do |command|
  begin
    cmd = command.shift
    case cmd
    when 'new'
      do_something
    else
      do_someotherthing
    end
  rescue => e
    error e.message
    error e.backtrace
  end
end

commands_for :list_function do |command|
  begin
    cmd = command.shift
    case cmd
    when "list_row"
      command.first
    when "list_end"
      false
    else
      throw :fatal, "list_error", "not a row #{command}"
    end
  rescue => e
    error e.message
    error e.backtrace
  end
end
    
