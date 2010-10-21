%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }

commands_for :view_server do |command|

  on :reset do
    View.reset
    return true 
  end

  on :ddoc do
    switch_state :design_document do |ddoc_state|
        
        on :new do |doc_name, doc|
          Design.new_doc doc_name, doc
        end

        otherwise do |doc, command, doc_body, req|
          
          context do |c|
            c[:ddoc] = doc
          end
          
          switch_state :document do |doc_state|
              
            on :shows do |show_func, doc, req|
              return Design.run(
                before: lambda do |cmd|
                  cmd.design_doc context(:ddoc)
                  cmd.function show_func
                  cmd.document doc
                  cmd.request req
                end,
                after: lambda do |respond|
                  if response.respond_to? :first and response.first == "error"
                    response
                  else
                    ["resp", response.is_a?(String) ? {"body" => response} : response]
                  end
                end
              )
            end

          end
        end

      end
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


#commands_for :design_document do |command|
#
#  on :new do |doc_name, doc|
#    Design.new_doc doc_name, doc
#  end
#
#  otherwise do |doc, command, doc_body|
#    switch_state :document do |context|
#      context['doc'] = doc
#      context['command'] = command
#      context['doc_body'] = doc_body
#    end
#  end
#
#  on_error do |e|
#    error e.message
#    error e.backtrace
#  end
#
#end
#
#commands_for :document do |command|
#
#  debugger
#  
#  on :show do |show_func, doc|
#    debugger
#  end
#
#end


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
    
