class ViewServer 
  class DesignDoc 
    class List 
      include StateProcessor
      
      def command command
        case command = command.shift
        when "list_row"
          command.first
        when "list_end"
          false
        else
          throw :fatal, "list_error", "not a row '#{command}'"
        end
      end
      
      
      def run(head_and_req)
        state do
          head, req = head_and_req.first
          @started = false
          @fetched_row = false
          @start_response = {"headers" => {}}
          @chunks = []
          tail = super(head, req)
          # if tail is an error, then just quit, otherwise, ignore tail for now.
          return tail if tail[0] == 'error' rescue nil
        
          get_row if ! @fetched_row
          @chunks.push tail if tail
          ["end", @chunks]
        end
      end
      
      def send(chunk)
        @chunks << chunk
        false
      end
      
      def get_row()
        @fetched_row = true
        __flush_chunks
        if ! @started
          @started = true
        end
      end
      
      def start(response)
        @start_response = response
      end
      
      def __flush_chunks
        response = if @started
          ["chunks", @chunks.dup]
        else
          ["start", @chunks.dup, @start_response]
        end
        CouchDB.write response
        @chunks.clear
      end
      
    end
  end
end
