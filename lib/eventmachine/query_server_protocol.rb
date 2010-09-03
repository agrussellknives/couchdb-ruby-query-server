require 'eventmachine'

module CouchDBQueryServerProtocol
  include EM::Protocols::LineText2
  
  @run = nil
  
  def receive_line data
    begin
     command = JSON.parse data if data
    rescue JSON::ParserError => e
      #an unparseable command - make "run" go fatal.
      return ['']
    rescue => e
      raise e
    end
    @run.call command
  end
  
  def send_data data
    old_send_data data.to_json
  end
  alias :old_send_data :send_data
  
  def run &block
    @run = block
  end
  
end