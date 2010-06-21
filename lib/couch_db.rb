%w(runner design view sandbox).each {|mod| require "#{File.dirname(__FILE__)}/couch_db/#{mod}.rb" }
require 'json'

module CouchDB
  extend self
  $realstdout = $stdout
  $realstdin = $stdin
  $stdout = $stderr
  $error = $stderr

  attr_accessor :debug, :wait_for_connection, :stop_on_error, :pipe, :pipe_dir
  
  def stderr_to=(val)
    $error = File.open(val,'wa')
  end

  def loop
      
    if @pipe then
      `mkfifo -m 777 #{@pipe_dir}/qs_pipe_in` unless File.exist?("#{@pipe_dir}/qs_pipe_in")
      `mkfifo -m 777 #{@pipe_dir}/qs_pipe_out` unless File.exist?("#{@pipe_dir}/qs_pipe_out")
      $pipe_in = File.open("#{@pipe_dir}/qs_pipe_in",'r+')
      $pipe_out = File.open("#{@pipe_dir}/qs_pipe_out",'w+')
      File.open('/tmp/couchdb_view_server.pid','w') do |f|
        f.write(Process.pid)
      end
      $pipe_in.sync = true
      $pipe_out.sync = true
      $stdin = $pipe_in
      $realstdout = $pipe_out
      log("started in pipe mode")
    end
    
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
    $error << "exit was called with ##{type} #{msg}"
    write([type,msg]) if type || msg
    Process.exit() unless @pipe
    # unless we're running in pipe_mode, this won't be reached
    @play_dead = true
    View.functions = []
    Design.documents = {}
    $pipe_in.close
    $pipe_out.close
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
        # you don't get here unless you're in pipe mode
      end
    rescue => e
      $error.puts e.message if @debug
      debugger if @stop_on_error
      write(e.message)
      false
    end
  end
  
end