class ViewServer 
  include StateProcessor
  include StateProcessor::StateProcessorWorker
  
  #we have to make a new runner to 
  #batch our results emit
  class MapRunner < CouchDB::Runner
    attr_reader :results

    def initialize(*args)
      @results = []
      super(*args)
    end

    def emit(key, value)
      @results.push([key, value])
    end
  end

  FUNCTIONS = []

  class << self  
    def add_map_function(funcstr)
      response = CouchDB::Sandbox.make_proc(funcstr)
      if response.is_a?(Proc)
        FUNCTIONS.push(response)
        true
      else
        response
      end
    end

    def reset
      FUNCTIONS.clear
    end
  end

  def map(doc)
    begin
      FUNCTIONS.map do |func|
        MapRunner.new(func).run(doc)
      end
    rescue ZeroDivisionError => e
      debugger
    end
  end
  
  def reduce(functions, kvs)
    keys, vals = kvs.transpose
    result = functions.map do |func|
      CouchDB::Sandbox.make_proc(func).call(keys, vals, false)
    end
    [true, result]
  end

  def rereduce(functions, vals)
    result = functions.map do |func|
      CouchDB::Sandbox.make_proc(func).call([], vals, true)
    end
    [true, result]
  end

end
