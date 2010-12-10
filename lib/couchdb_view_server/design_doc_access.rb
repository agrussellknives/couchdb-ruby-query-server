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


