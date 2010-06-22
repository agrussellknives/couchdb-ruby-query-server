require File.dirname(__FILE__) + '/test_helper'

context "debugging works" do
  
  setup do
    @dbg_func = "lambda { |doc| 
      debugger; 
      emit(doc)
    }"
    @vs = IO.popen('bin/couchdb_view_server --unsafe --debug','r+')
    @vs << ["add_fun","
        lambda { |doc| 
          debugger; 
          emit(doc)
        }"]
    @vs.puts
    @vs << ["map_doc","{'_id':'foo'}"]
    @vs.puts
    @vs.flush
    @db = IO.popen('rdebug -c','r+')
  end  
    
  def wait_for_debugger(regex,time)
     now = Time.new.to_i
     success = false
     v = ''
     loop do
       begin
         v = @db.read_nonblock 1000
       rescue Errno::EAGAIN => e
         # keep trying, keep trying, don't give up, don't give up.
         $stdout << '.'
       end
       if v =~ regex then
         success = true
         break
       end
       # wait 2 seconds
       break if Time.new.to_i - now > time     
     end
     success ? v : false
  end
  
  test "enters debug mode" do    
    assert_equal "Connected.\n", wait_for_debugger(/Connected\./,1)
    @db.flush
  end
  
  test "lists function" do
    list = "[1, 5] in /tmp/eval-4.rb\n   1  \n   2          lambda { |doc| \n   3            debugger; \n=> 4            emit(doc)\n   5          }\n"
    @db.puts 'l ='
    @db.flush
    assert_equal list, wait_for_debugger(/#{@dbg_func}/,1)
    @db.flush
  end
  
  teardown do 
    @vs.close
    @db.puts 'q'
    @db.puts 'y'
    @db.flush
    @db.close
  end
  
end