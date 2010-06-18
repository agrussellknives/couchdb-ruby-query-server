module CouchDB
  module View
    extend self
  
    @@functions = []

    def add_map_function(funcstr)
      response = Sandbox.make_proc(funcstr)
      @@functions.push(response)
      true
    end

    def reset
      @@functions.clear
    end

    def map(doc)
      @@functions.map do |func|
        MapRunner.new(func).run(doc)
      end
    end

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

    def reduce(functions, vals)
      keys = vals.map {|val| val.shift }
      vals = vals.map {|val| val.shift }
      result = functions.map do |func|
        Sandbox.make_proc(func).call(keys, vals, false)
      end
      [true, result]
    end

    def rereduce(functions, vals)
      result = functions.map do |func|
        Sandbox.make_proc(func).call([], vals, true)
      end
      [true, result]
    end

  end
end
