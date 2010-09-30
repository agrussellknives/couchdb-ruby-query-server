require 'ruby-debug'
require 'eval-debugger'

require 'activesupport'

#stdlib
require 'json'
require 'eventmachine'



# couchdb requires
%w(runner design view sandbox arguments).each {|mod| require "#{File.dirname(__FILE__)}/couch_db/#{mod}" }

#event machine
%w(query_server_protocol state_processor).each {|mod| require "#{File.dirname(__FILE__)}/eventmachine/#{mod}" }


module CouchDB
  class UnknownStateError < StandardError; end
  include Arguments
  extend self
  $realstdout = $stdout
  $realstdin = $stdin
  $stdout = $stderr
  $error = $stderr
  
  STATE_PROCESSORS = {}
  
  attr_accessor :debug, :wait_for_connection, :stop_on_error
  
  def state= key
    @state = key.intern
  end
  
  def state key = :default, protocol = CouchDBQueryServerProtocol, &block
    # this method does double duty.
    return @state unless key and block_given?
    
  
    key = key.intern
    STATE_PROCESSORS[key] = {}
    if block_given? then
      STATE_PROCESSORS[key] = StateProcessorFactory.create(key, protocol, &block)
    else
      STATE_PROCESSORS[key] = StateProcessorFactory.create(key, NilProtocol) do |command|
        puts command
      end
    end
  end
  
  def stderr_to=(val)
    $error = File.open(val,'a+')
  end
  
  def loop initial_state = nil
    unless (initial_state and STATE_PROCESSORS.has_key? initial_state.intern) then
      raise UnknowStateError 'CouchLoop was started in an unknown or nil state.'
    end
    state = initial_state
    (log 'Waiting for debugger...'; debugger) if wait_for_connection  
    EventMachine::run do
      @pipe = EM.attach $stdin, STATE_PROCESSORS[state][:protocol] do |pipe|
        pipe.run do |command|
          res = STATE_PROCESSORS[state][:block].call(command)
          write res
        end
      end
    end
  end
  
  def log(thing)
    @pipe.send_data(["log", thing.to_json])
  end
  
  def exit(type = nil,msg = nil)
    @pipe.send_data([type,msg]) if type || msg
    Process.exit()
  end

  def write(response)
    @pipe.send_data response
  end
  
end