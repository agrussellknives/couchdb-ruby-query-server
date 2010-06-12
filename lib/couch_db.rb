%w(runner design view sandbox).each {|mod| require "#{File.dirname(__FILE__)}/couch_db/#{mod}" }
require 'json'

module CouchDB
  extend self
  $realstdout = $stdout
  $stdout = $stderr
  
  def loop
    while command = read do
      write run(command)
    end
  end
  
  def read
    foo = $stdin.gets
    JSON.parse foo if foo
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
        ["error", "unknown_command"]
      end
    rescue => e
      false
    end
  end
  
end