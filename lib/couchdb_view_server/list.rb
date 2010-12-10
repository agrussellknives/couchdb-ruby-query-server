require_relative 'design_doc_access'


module ListFunctions
  def send(chunk)
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
end

class ViewServer 
  class DesignDoc 
    class List 
      include StateProcessor
      include StateProcessor::StateProcessorWorker
      include DesignDocAccess
      include ListFunctions

      def resume_with(*args)
        result = @fb.resume *args
        if block_given?
          yield result
        else
          result
        end
      end
  
      def run lists, list_func, *args
        # lists is always going to be :lists
        comp_function = ddoc[:lists][list_func]
        # resetting the context for the runner at the beginning
        # of every executiong feels really dirty
        @start_response = {:headers => {}}
        @started = false
        @chunks = []
        comp_function = CouchDB::Sandbox.make_proc comp_function
        
        @fb = Fiber.new do
          @chunks << CouchDB::Runner.new(comp_function,self).run(*args) 
          [:end, @chunks]
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
