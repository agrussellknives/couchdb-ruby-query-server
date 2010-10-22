class View


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
  
  def reduce(functions, vals)
    debugger
    keys = vals.map {|val| val.shift }
    vals = vals.map {|val| val.shift }
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
