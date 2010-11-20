class ViewServer 
  class DesignDoc 
    class List 
      include StateProcessor
      include StateProcessor::StateProcessorWorker
      include DesignDocAccess
      
      def send(chunk)
        @chunks ||= []
        @chunks << chunk
        false
      end
      
      def get_row()
        @fetched_row = true
        __flush_chunks
        if ! @started
          @started = true
        end
      end
      
      def start(response)
        @start_response = response
      end
      
      def __flush_chunks
        response = if @started
          ["chunks", @chunks.dup]
        else
          ["start", @chunks.dup, @start_response]
        end
        CouchDB.write response
        @chunks.clear
      end
  
      def run lists, list_func, *args
        # lists is always going to be :lists
        debugger
        comp_function = ddoc[:lists][list_func]
        @start_response = {:headers => {}}
        comp_function = CouchDB::Sandbox.make_proc comp_function
        result = CouchDB::Runner.new(comp_function,self).run(*args)

        if block_given?
          yield result
        else
          result
        end
      end
      
            
    end
  end
end
