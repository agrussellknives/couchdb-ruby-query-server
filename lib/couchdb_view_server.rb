%w{design view list}.each {|mod| require "#{File.dirname(__FILE__)}/couchdb_view_server/#{mod}" }


class ViewServer 

  puts 'processing new command from ViewServer'
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
        ## THINGS HERE ARE ONLY RUN ONCE THIS IS KINDA SURPRISING AND WEIRD
        class DesignDoc 
          commands do
            stop_after do  
              on :new do |doc_name, doc|
                new_doc doc_name, doc
              end
            end

            on do |design_doc, command, doc_body, req|
              
              #i'm not really fond of this. I'm thinking maybe we
              #have some kind of "consumption" word in the on match, or something.
              #since an undecorated "on" shouldn't "match" the command
              consume_command! 
              
              # call on the worker before any action is taken
              context! do
                @ddoc = design_doc
              end
              
              on :lists do |func,doc,req|
                switch_state List do
                  class List
                    commands do
                      resume_here

                      on :list_row do |req|
                        puts 'list row'
                      end

                      on :list_end do
                        puts 'list end'
                      end
                      
                      on do |list_func, doc, req|
                        run list_func, doc, req do |result|
                          puts result 
                        end
                      end
                    end
                  end
                end
              end

              switch_state Document do
                class Document
                  commands do
                    on :shows do |show_func, doc, req|
                      # execute an evaled function in the context of the current worker
                      # the exact semantics of "run" depend on the implementation of run
                      # within the worker object.  By default it just raises "NotImplementedError"
                      # basically, thought, it will bass run :shows, *args
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
                      #filters should coerce all results to boolean
                      results = docs.map do |doc|
                        !!(run filter,doc,req)
                      end
                      stop_with [true, results]
                    end

                    on :updates do |func, doc, req|
                      doc.untrust if doc.respond_to?(:untrust)
                      unless req["method"] == "GET" 
                        run func, doc, req do |doc, result|
                          result = {"body" => result} if result.kind_of? string
                          stop_with ["up",doc,result]
                        end
                      end
                      stop_with ["error", "method_not_allowed", "update functions do not allow get"]
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
