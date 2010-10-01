require 'singleton'
require 'active_support'


class ProcessorConflictError < StandardError; end
class ProcessorDoesNotRespond < StandardError
  def initialize command
    @command = command
  end
end


class StateProcessorFactory
  include Singleton
  class << self
    def create state, protocol, &block
      class_name = state.to_s.camelize
      unless const_defined? class_name.to_sym
          klass = Class.new(Object) do
            @protocol = protocol
            class << self
              attr_accessor :protocol
            end
            def switch_state state
              CouchDB.state = state.to_sym
              raise ProcessorDoesNotRespond, cmd
            end
            def error e
              $error.puts e if CouchDB.debug
            end
            def exit e
              CouchDB.exit e
            end
            def inspect
               "#<#{self.class}:#{self.object_id << 1} @protocol: #{@protocol}>"
            end
          end
          const_set(class_name.to_sym,klass) 
          const_get(class_name.to_sym).send :define_method, :process, &block
          const_get(class_name.to_sym) # return the class
      else
        raise ProcessorConflictError, "You cannot create two Processors for the same state in a single process."
      end
    end  
  end
end
