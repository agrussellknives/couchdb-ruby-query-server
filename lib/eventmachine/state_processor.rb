require 'singleton'
require 'query_server_protocol'

class ProcessorConflictError < StandardError; end

class StateProcessorFactory
  include Singleton
  class << self
    def create state, protocol, &block
      class_name = state.to_s.camelize
      unless const_defined? class_name.to_sym
          const_set(class_name.to_sym) = Class.new(Object) do
            attr_accessor :protocol
            def initialize protocol
              protcol = @protocol || CouchDBQueryServerProtocol
            end
            def inspect
               "#<#{self.class}:#{self.object_id << 1} @protocol: #{@protocol}>"
            end
          end
          const_get(class_name.to_sym).send :define_method, :process, &block
      else
        raise ProcessorConflictError, "You cannot create two Processors for the same state in a single process."
      end
    end  
  end
end