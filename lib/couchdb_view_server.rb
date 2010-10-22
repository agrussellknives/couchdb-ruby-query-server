%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }

commands_for :view_server do |command|
  
  on_error do |e|
    debugger
    error e.message
    error e.backtrace
  end

  on :reset do
    View.reset
    stop_with true 
  end

  on :ddoc do
    switch_state :design_document do |ddoc_state|
        
        on :new do |doc_name, doc|
          Design.new_doc doc_name, doc
        end

        otherwise do |ddoc, command, doc_body, req|
          
          context do |c|
            c[:ddoc] = ddoc
          end
          
          switch_state :document do |doc_state|

            on :shows do |show_func, doc, req|
              result = Design.run(doc, req) do
                setup do |cmd|
                  cmd[:design_doc] = context(:ddoc)
                  cmd[:function] = show_func
                end
                
                after do |response|
                  if response.respond_to? :first and response.first == "error"
                    response
                  else
                    ["resp", response.is_a?(String) ? {"body" => response} : response]
                  end
                end
              end
              stop_with result
            end

          end
        end

      end
  end

  on :add_fun do |func|
    stop_with View.add_map_function(func)
  end

  on :map_doc do |doc|
    stop_with View.new.map(doc)
  end


  on :reduce do |func, *groups|
    View.new.reduce(func, groups)
  end

  on :rereduce do
    View.new.rereduce(command.shift, command.shift)
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
    
