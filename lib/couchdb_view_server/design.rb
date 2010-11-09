require 'active_support/hash_with_indifferent_access'

#TODO - make sectional into a separate gem so i don't have to do this
require_relative '../../../couchdb-sectional/eventmachine/state_processor'

class ViewServer 
  class DesignDoc
    include StateProcessor
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
   
    # i am probably not going to need this
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
    
    
  end
end
