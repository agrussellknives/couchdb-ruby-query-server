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
        row = flush
        @started = true unless @started
        row
      end
      
      def start(response)
        @start_response = response
      end
      
      def flush
        result = if @started
          [:chunks, @chunks]
        else
          [:start, @chunks, @start_response]
        end
        row = Fiber.yield result
        @chunks.clear
        row 
      end
      private :flush

      def resume_with(*args)
        @fb.resume *args 
      end
  
      def run lists, list_func, *args
        # lists is always going to be :lists
        comp_function = ddoc[:lists][list_func]
        @start_response = {:headers => {}}
        comp_function = CouchDB::Sandbox.make_proc comp_function
        
        @fb = Fiber.new do
          CouchDB::Runner.new(comp_function,self).run(*args)
        end
        result = @fb.resume

        if block_given?
          yield result
        else
          result
        end
      end
      
            
    end
  end
end
