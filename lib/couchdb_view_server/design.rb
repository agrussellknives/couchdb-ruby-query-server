require 'active_support/hash_with_indifferent_access'

#TODO - make sectional into a separate gem so i don't have to do this
require_relative '../../../couchdb-sectional/eventmachine/state_processor'

class ViewServer 
  class DesignDoc
    include StateProcessor
    include StateProcessor::StateProcessorWorker
    
    DOCUMENTS = HashWithIndifferentAccess.new 
    
    class << self

      def new_doc doc_name, doc
        DOCUMENTS[doc_name] = doc
        true
      end
    end

    class Document 
      include StateProcessor
      include StateProcessor::StateProcessorWorker

      class HaltedFunction < StandardError; end

      attr_accessor :ddoc

      def run command, *args, &block
        funcs = ViewServer::DesignDoc::DOCUMENTS[ddoc][command]
        # we need to make sure that we got something hashlike
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
    
  end
end
