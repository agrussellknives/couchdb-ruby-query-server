%w(runner design view sandbox).each {|mod| require "#{File.dirname(__FILE__)}/couch_db/#{mod}.rb" }
require 'json'

module CouchDB
  extend self
  $realstdout = $stdout
  $realstdin = $stdin
  $stdout = $stderr
  $error = $stderr

  attr_accessor :debug, :wait_for_connection, :stop_on_error
  
  def stderr_to=(val)
    $error = File.open(val,'a+')
  end

  def loop
    debugger if @wait_for_connection
    while command = read do
      write run(command)
    end
  end
  
  def read
    begin
      foo = $stdin.gets
      JSON.parse foo if foo
    rescue JSON::ParserError => e
      #an unparseable command - make "run" go fatal.
      return ['']
    rescue => e
      raise e
    end
  end
  
  def log(thing)
    write(["log", thing.to_json])
  end
  
  def exit(type = nil,msg = nil)
    write([type,msg]) if type || msg
    Process.exit()
  end

  def write(response)
    $realstdout.puts response.to_json
    $realstdout.flush
  end
  
  def run(command=[])
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
      debugger if @stop_on_error
      write(e.message)
      e.message
    end
  end
  
end