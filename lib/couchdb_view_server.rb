CouchDB.state :view_server do |command|
  return "bob"
  begin
    cmd = command.shift
    case cmd
    when 'reset'
      View.reset
      true
    when 'ddoc'
      Design.handle(command)
    when 'add_fun'
      View.add_map_function(command.shift)
    when 'map_doc'
      View.map(command.shift)
    when 'reduce'
      View.reduce(command.shift, command.shift)
    when 'rereduce'
      View.rereduce(command.shift, command.shift)
    else
      # this is actually a fatal.
      exit('error','unknown_command')
    end
  rescue => e
    $error.puts e.message if @debug
    $error.puts e.backtrace if @debug
  end
end