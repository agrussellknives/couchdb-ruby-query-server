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
        flush
        if ! @started
          @started = true
        end
      end
      
      def start(response)
        @start_response = response
      end
      
      def flush
        result = if @started
          ["chunks", @chunks.dup]
        else
          ["start", @chunks.dup, @start_response]
        end
        debugger
        ## THIS SHOULD BE ANSWERING OR STOPPING THE RUN
        CouchDB.write response
        @chunks.clear
      end
      private :flush
  
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
