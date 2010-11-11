%w{design view}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }


class ViewServer 

  protocol CouchDBQueryServerProtocol

  commands do
    on_error do |e|
      error e.message
      error e.backtrace
    end
    
    on :reset do
      reset
      return true 
    end

    on :add_fun do |func|
      add_map_function(func)
    end

    # TODO, change this to a block so you don't have to
    # explcicitly instantiate a worker object
    on :map_doc do |doc|
      # this should read like execute { map(doc) }
      new.map(doc)
    end

    on :reduce do |func, kv_pairs|
      new.reduce(func, kv_pairs)
    end

    on :rereduce do |func, kv_pairs|
      new.rereduce(func, kv_pairs)
    end

    on :ddoc do
      switch_state DesignDoc do
        class DesignDoc 
          commands do
            on :new do |doc_name, doc|
              new_doc doc_name, doc
            end

            otherwise do |design_doc, command, doc_body, req|
              switch_state Document do
                debugger

                context do |c|
                  ddoc = design_doc
                end

                class Document
                  
                  commands do
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

                    on :updates do |func, doc, req|
                      debugger
                      doc, request = command.shift
                      doc.untrust if doc.respond_to?(:untrust)
                      if request["method"] == "GET"
                        ["error", "method_not_allowed", "Update functions do not allow GET"]
                      else
                        doc, response = CouchDB::Runner.new(func, design_doc).run(doc, request)
                        response = {"body" => response} if response.kind_of?(String)
                        ["up", doc, response]  
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
    
