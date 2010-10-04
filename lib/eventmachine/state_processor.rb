require 'singleton'
require 'active_support'


class ProcessorConflictError < StandardError; end
class ProcessorExit < StandardError; end
class ProcessorDoesNotRespond < StandardError; end

class ProcessorDelegatesTo < StandardError
  attr_reader :state
  def initialize state
    @state = state
  end
end

class StateProcessorFactory
  include Singleton
  class << self
    def create state, protocol, &block
      class_name = state.to_s.camelize
      unless const_defined? class_name.to_sym
          klass = Class.new(Object) do
            @state = state
            @protocol = protocol
            @commands = block
            class << self
              attr_accessor :protocol
              attr_accessor :state
              attr_reader :commands
            end
            attr_accessor :command
            def initialize
              @command = nil
              @executed_command = nil
            end
            def switch_state state
              raise ProcessorDelegatesTo, state 
            end
            def error e
              $error.puts e if CouchDB.debug
            end
            def exit e
              raise ProcessorExit, e
            end
            def on_error error=nil
              yield error if error
            end
            def on cmd
              if cmd == @command
                yield @command
                @executed_command = @command
              end
            end
            def process cmd 
              @command = cmd.shift.to_sym
              begin
                instance_exec(command,&(self.class.commands))
              rescue LocalJumpError => e
                return e.exit_value if e.reason == :return
              rescue StandardError => e
                on_error e 
              end
            
              if @executed_command == nil
                cmd = @command
                @command = nil
                raise ProcessorDoesNotRespond, "Processor does not respond to #{cmd}"
              end

            end
            def inspect
               "#<#{self.class}:#{self.object_id << 1} @protocol: #{@protocol}>"
            end
          end
          const_set(class_name.to_sym,klass) 
          const_get(class_name.to_sym) # return the class
      else
        raise ProcessorConflictError, "You cannot create two Processors for the same state in a single process."
      end
    end  
  end
end
