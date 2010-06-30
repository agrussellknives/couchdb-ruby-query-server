module CouchDB
  class Runner
   
    class HaltedFunction < StandardError; end
    class FatalError < StandardError; end

    attr_accessor :error

    def initialize(func, design_doc = {})
      @func = func
      @design_doc = design_doc
    end

    def run(*args)
      begin
        results = instance_exec *args, &@func
        if @results then @results else results end
      rescue HaltedFunction => e
        $error.puts(e) if CouchDB.debug
        @error
      rescue => e
        log [e.class.to_s,e.message]
        debugger if CouchDB.stop_on_error
        results = []
      end
    end

    def throw(error, *message)
      begin
        @error = if [:error, :fatal, "error", "fatal"].include?(error)
          errorMessage = ["error", message].flatten
          raise FatalError, errorMessage if [:fatal,"fatal"].include?(error)
          errorMessage
        else
          {error.to_s => message.join(', ')}
        end
        raise HaltedFunction
      rescue FatalError => e
        CouchDB.write(e.message)
        CouchDB.exit
      end
    end

    def log(thing)
      CouchDB.write(["log", thing.to_json])
    end

  end
end
