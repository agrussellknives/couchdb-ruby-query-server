%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }


class ViewServer 

  protocol CouchDBQueryServerProtocol

  commands do
    on_error do |e|
      error e.message
      error e.backtrace
    end

    stop_after do
      # calls class method reset without arguments
      on :reset 
    
      # calls class method add_fun with argument func
      on :add_fun do |func|
        add_fun func
      end

      # calls instance method map with parameter doc
      # i could make it 'execute doc' but it seems i should
      # be slightly more explicit than that
      on :map_doc do |doc|
        execute :map, doc 
      end
      
      on :reduce do |func, kv_pairs|
        execute :reduce, func, kv_pairs
      end

      on :rereduce do |func, kv_pairs|
        execute :rereduce, func, kv_pairs 
      end
    end
   
    on :ddoc do
      switch_state DesignDoc do
        class DesignDoc 
          commands do
            on :new do |doc_name, doc|
              new_doc doc_name, doc
            end

            on do |design_doc, command, doc_body, req|
              switch_state Document do
                  
                context do
                  @ddoc = design_doc
                end

                class Document
                  commands do
                    
                    on :shows do |show_func, doc, req|
                      run show_func, doc, req do |result|
                        stop_with result if result.respond_to? :first and result.first == "error"
                        stop_with ["resp",result.is_a?(String) ? {"body" => result} : result]
                      end
                    end

                    on :validate_doc_update do |new_doc, old_doc, user_ctx|
                      run new_doc, old_doc, user_ctx do |result|
                        stop_with result if result.respond_to? :has_key? and result.has_key? :forbidden
                        stop_with 1 
                      end
                    end

                    on :filters do |filter, *docs, req|
                      results = docs.map do |doc|
                        run filter,doc,req
                      end
                    end

                    on :updates do |func, doc, req|
                      doc.untrust if doc.respond_to?(:untrust)
                      unless req["method"] == "GET" 
                        run func, doc, req do |result|
                          result = {"body" => result} if result.kind_of? String
                          stop_with ["up",doc,result]
                        end
                      end
                      stop_with ["error", "method_not_allowed", "Update functions do not allow GET"]
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
    
