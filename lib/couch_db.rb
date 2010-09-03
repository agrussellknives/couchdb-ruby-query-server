require 'ruby-debug'
require 'eval-debugger'

#stdlib
require 'json'
require 'eventmachine'

# couchdb requires
%w(runner design view sandbox).each {|mod| require "#{File.dirname(__FILE__)}/couch_db/#{mod}" }

#event machine
%w(query_server_protocol).each {|mod| require "#{File.dirname(__FILE__)}/eventmachine/#{mod}" }


module CouchDB
  extend self
  $realstdout = $stdout
  $realstdin = $stdin
  $stdout = $stderr
  $error = $stderr
  
  STATE_PROCESSORS = {}
  
  attr_accessor :debug, :wait_for_connection, :stop_on_error, :state
  
  def default &block
    if block_given? then
      STATE_PROCESSORS['default'] = block
    else
      STATE_PROCESSORS['default'] = lambda do |command|
        puts command
      end
    end
  end
  
  def stderr_to=(val)
    $error = File.open(val,'a+')
  end
  
  def loop
    (log 'Waiting for debugger...'; debugger) if @wait_for_connection  
    EventMachine::run do
      @pipe = EM.attach $stdin, CouchDBQueryServerProtocol do |pipe|
        pipe.run do |command|
            STATE_PROCESSORS[state].call(command)
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

CouchDB.default do 
  begin
    cmd = command.shift
    case cmd
    when 'reset'
      View.reset
      true
    when 'ddoc'
      Design.handle(command)
    when 'add_fun'
      View.add_map_function(command.shift)
    when 'map_doc'
      View.map(command.shift)
    when 'reduce'
      View.reduce(command.shift, command.shift)
    when 'rereduce'
      View.rereduce(command.shift, command.shift)
    else
      # this is actually a fatal.
      exit('error','unknown_command')
    end
  rescue => e
    $error.puts e.message if @debug
    $error.puts e.backtrace if @debug
  end
end
  