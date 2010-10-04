%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }

commands_for :view_server do |command|
 
  on :reset do
    View.reset
    return true 
  end

  on :test do
    puts "called test block"
    break
  end

  on :test do
    puts "called test again"
  end

  on :ddoc do
    switch_state :design_document
  end

  on :add_fun do
    View.add_map_function(command.shift)
  end

  on :map_doc do
    View.new.map(command.shift)
  end

  on :reduce do
    View.new.reduce(command.shift, command.shift)
  end

  on :rereduce do
    View.new.rereduce(command.shift, command.shift)
  end

  on_error do |e|
    error e.message
    error e.backtrace
  end
end

  
commands_for :design_document do |command|
  debugger

  on :new do |cmd|
    Design.new_doc cmd
  end

  otherwise do |cmd|
    Design.action cmd
  end

  on_error do |e|
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
    
