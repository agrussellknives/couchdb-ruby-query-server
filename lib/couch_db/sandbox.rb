module CouchDB
  module Sandbox
    extend self
    
    def safe
      @safe ||= true
    end
    
    def safe=(bool)
      @safe = !! bool
    end
    
    def make_proc(string)
      begin
        value = run(string)
        unless value.is_a?(Proc)
          value = ["error", "compilation_error", "expression does not eval to a proc: #{string}"]
        end
      rescue SyntaxError => e
        raise e, value
      end
      value
    end
    
    def run(string)
      if safe
        lambda { $SAFE=4; eval(string) }.call
      else
        eval(string)
      end
    end
    
  end
end
