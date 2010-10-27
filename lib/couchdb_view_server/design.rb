require 'active_support/hash_with_indifferent_access'

#TODO - make sectional into a separate gem so i don't have to do this
require_relative '../../../couchdb-sectional/eventmachine/state_processor'

class Design
  extend StateProcessor::StateProcessorWorker
  
  class HaltedFunction < StandardError; end
  
  DOCUMENTS = HashWithIndifferentAccess.new 
  
  class << self

    attr_accessor :ddoc

    def new_doc doc_name, doc
      DOCUMENTS[doc_name] = doc
      true
    end

    def run command, *args, &block
      funcs = DOCUMENTS[@ddoc][command]
      if funcs.respond_to? :keys
        comp_function = funcs[args.shift]
      else
        comp_function = funcs
      end

      #TODO - cache the compiled version of the function so that
      # it isn't compiled afresh on each request.  if we want
      # we can add a external to reset the cache later

      comp_function = CouchDB::Sandbox.make_proc comp_function
      result = CouchDB::Runner.new(comp_function).run(*args)
      
      if block_given? 
        yield result
      else
        result
      end
    end
    
  end

  
  def lists(func, design_doc, head_and_req)
    ListRenderer.new(func, design_doc).run(head_and_req)
  end
  
  def updates(func, design_doc, command)
    doc, request = command.shift
    doc.untrust if doc.respond_to?(:untrust)
    if request["method"] == "GET"
      ["error", "method_not_allowed", "Update functions do not allow GET"]
    else
      doc, response = CouchDB::Runner.new(func, design_doc).run(doc, request)
      response = {"body" => response} if response.kind_of?(String)
      ["up", doc, response]  
    end
  end
  
  class ListRenderer < CouchDB::Runner
    
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
