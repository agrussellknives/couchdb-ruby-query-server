%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }


class ViewServer < StateProcessor

  protocol CouchDBQueryServerProtocol

  commands do
    on_error do |e|
      error e.message
      error e.backtrace
    end
    
    on :reset do
      reset
      stop_with true 
    end

    on :add_fun do |func|
      stop_with add_map_function(func)
    end

    on :map_doc do |doc|
      stop_with new.map(doc)
    end

    on :reduce do |func, kv_pairs|
      stop_with new.reduce(func, kv_pairs)
    end

    on :rereduce do |func, kv_pairs|
      stop_with new.rereduce(func, kv_pairs)
    end

    on :ddoc do
      switch_state DesignDoc do
        class DesignDoc < StateProcessor
          debugger
          commands do
            on :new do |doc_name, doc|
              new_doc doc_name, doc
            end

            otherwise do |design_doc, command, doc_body, req|
              @ddoc = design_doc 
              
              switch_state Document do
                class Document < State Processor
                  on :shows do |show_func, doc, req|
                    execute show_func, doc, req do |result|
                      stop_with result if result.respond_to? :first and result.first == "error"
                      stop_with ["resp",result.is_a?(String) ? {"body" => result} : result]
                    end
                  end

                  on :validate_doc_update do |new_doc, old_doc, user_ctx|
                    execute new_doc, old_doc, user_ctx do |result|
                      stop_with result if result.respond_to? :has_key? and result.has_key? :forbidden
                      stop_with 1 
                    end
                  end

                  on :filters do |filter, *docs, req|
                    results = docs.map do |doc|
                      execute filter,doc,req
                    end
                    stop_with [true, results]
                  end
                end
              end
            end
          end
        end
      end
    end
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


#commands_for :list_function do |command|
#  begin
#    cmd = command.shift
#    case cmd
#    when "list_row"
#      command.first
#    when "list_end"
#      false
#    else
#      throw :fatal, "list_error", "not a row #{command}"
#    end
#  rescue => e
#    error e.message
#    error e.backtrace
#  end
#end
    
