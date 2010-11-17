require 'active_support/hash_with_indifferent_access'

#TODO - make sectional into a separate gem so i don't have to do this
require_relative '../../../couchdb-sectional/eventmachine/state_processor'

module DesignDocAccess
  extend ActiveSupport::Concern
  include CouchDB::Exceptions

  module ClassMethods
    def ddoc(key=nil)
      ViewServer::DesignDoc::DOCUMENTS[key]
    end
  end 

  def ddoc
    self.class.ddoc(@ddoc)
  end

  def ddoc= name
    @ddoc = name
  end

  def throw(error, *message)
    # this function is completely ludicrous, but it's a problem with the protocol
    #
    e_sym = error.to_sym
    case e_sym 
      when :error, :fatal
        msg = [:error, message].flatten  
        ex = e_sym == :fatal ? FatalError.new(msg) : HaltedFunction.new(msg) 
        raise ex
      else
        raise HaltedFunction, {error => message.join(', ')}
    end
 end

  def log(thing)
    CouchDB.write(["log", thing.to_json])
  end
end
   
class ViewServer 
  class DesignDoc
    include StateProcessor
    include StateProcessor::StateProcessorWorker
    
    DOCUMENTS = HashWithIndifferentAccess.new

    DOCUMENTS.default = DOCUMENTS
    
    class << self

      def new_doc doc_name, doc
        DOCUMENTS[doc_name] = doc
        true
      end
    end

    class Document 
      include StateProcessor
      include StateProcessor::StateProcessorWorker
      include DesignDocAccess
       
      def run command, *args, &block
        funcs = ddoc[command]
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
        result = CouchDB::Runner.new(comp_function,self).run(*args)
        
        if block_given? 
          yield result
        else
          result
        end
      end

    end
  end
end
