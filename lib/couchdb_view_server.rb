%w{design view list}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }


class ViewServer 

  puts 'processing new command from ViewServer'
  protocol CouchDBQueryServerProtocol

  #on error should be here as well


  # LET'S SPEAK SECTIONAL
  commands do
    # we should move this into the protocol
    on_error do |e|
      error e.message
      error e.backtrace
    end

    # immediately returns after the first match
    return_after do
      # calls class method reset without arguments
      on :reset do
        execute :reset
      end
      on :add_fun do |func|
        execute :add_fun, func
      end

      # calls reduce / rereduce in the worker and passes any additional
      # argument in as they are recieved
      on :reduce 
      on :rereduce 
     
      # calls instance method map with argument doc
      on :map_doc do |doc|
        map doc 
      end
      
    end
  
    on :ddoc do
      switch_state DesignDoc do
        commands do

          on :new do |doc_name, doc|
            return execute(:new_doc,doc_name,doc)
          end

          # should we put saved parameters at the beginning
          on _! do |*,design_doc|
            
            # call on the worker before any action is taken
            context do
              @ddoc = design_doc
            end
            
            on :lists do 
              switch_state List do
                commands do
                  # for now we're using "pass" to mean - return this but don't switch the
                  # state back to our parent
                  on _! do |doc, req, list_func|
                    run list_func, doc, req do |result|
                      answer result do
                        on :list_row do |row|
                          resume_with row do |res|
                            if res.try(:first) == :end
                              return res
                            else
                              answer res
                            end
                          end
                        end
                        on :list_end do
                          return resume_with false
                        end
                        on do |cmd|
                          return [:fatal, "list_error", "not a row #{cmd}"] 
                        end
                      end 
                    end
                  end
                end
              end
            end
            
            switch_state Document do
              commands do
                on :shows do |show_func, doc, req|
                  # execute an evaled function in the context of the current worker
                  # the exact semantics of "run" depend on the implementation of run
                  # within the worker object.  By default it just raises "NotImplementedError"
                  run show_func, doc, req do |result|
                    return result if result.try(:first) == :error
                    return ["resp", result.is_a?(String) ? {"body" => result} : result]
                  end
                end

                on :validate_doc_update do |new_doc, old_doc, user_ctx|
                  run new_doc, old_doc, user_ctx do |result|
                    return result if result.try(:has_key?, :forbidden)
                    return 1 
                  end
                end

                on :filters do |filter, *docs, req|
                  #filters should coerce all results to boolean
                  results = docs.map do |doc|
                    !!(run filter,doc,req)
                  end
                  return [true, results]
                end

                on :updates do |func, doc, req|
                  doc.untrust if doc.respond_to?(:untrust)
                  unless req["method"] == "GET" 
                    run func, doc, req do |doc, result|
                      result = {"body" => result} if result.kind_of? String
                      return ["up",doc,result]
                    end
                  end
                  return [:error, "method_not_allowed", "update functions do not allow get"]
                end
              end
            end
          end
        end
      end
    end
  end
end
