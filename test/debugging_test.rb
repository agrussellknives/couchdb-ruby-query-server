require File.dirname(__FILE__) + '/test_helper'
require 'test/unit'

class Test::Unit::TestCase
  def wait_for_debugger(time = 1)
     now = Time.now.to_f
     v = ''
     v = loop do
       begin
         v << @db.read_nonblock(1500)
       rescue Errno::EAGAIN => e
         # keep trying, keep trying, don't give up, don't give up.
       end
       # wait for the debugger... don't use timeout, since it deals in seconds.
       break v if Time.now.to_f - now > time.to_f
     end
  end
end

context "connection is refused in safe mode" do
    
  setup do
    @vs = IO.popen('bin/couchdb_view_server --debug --wait','r+')
  end
  
  test "connection refused" do  
    assert_raises EOFError do
      @db = IO.popen('rdebug -c','r+')
      wait_for_debugger
    end
  end
  
  teardown do
    @db.close
    @vs.close
  end
end

context "wait for debugger at start" do
  
  setup do
    @vs = IO.popen('bin/couchdb_view_server --unsafe --debug --wait','r+')
    @db = IO.popen('rdebug -c','r+')
  end
  
  test "wait for debugger" do
   expect = %{Connected.
(rdb:1) }
    assert_equal expect, wait_for_debugger
  end
  
  teardown do
    @db.puts 'q'
    @db.puts 'y'
    @db.flush
    @db.close
    @vs.close
  end
end

context "crash debugging works" do
  setup do
    @vs = IO.popen('bin/couchdb_view_server --unsafe --debug --stop-on-error -f /dev/null','r+')
    @vs << ["add_fun","lambda { raise RuntimeError }"]
    @vs.puts
    @vs << ["map_doc","{'_id':'foo'}"]
    @vs.puts
    @vs.flush
    @db = IO.popen('rdebug -c','r+')
  end
  
  
  test "crash debugging" do
    expect = %{Connected.
(rdb:1) }
    assert_equal expect, wait_for_debugger
  end
  
  teardown do
    @db.puts 'q'
    @db.puts 'y'
    @db.flush
    @db.close
    @vs.close
  end
  
end
  

context "debugging works" do
  
  setup do    
    @vs = IO.popen('bin/couchdb_view_server --unsafe --debug -f /dev/null','r+')
    @vs << ["add_fun","
        lambda { |doc| 
          debugger;
          doc.size
          emit(doc)
        }"]
    @vs.puts
    @vs << ["map_doc","{'_id':'foo'}"]
    @vs.puts
    @vs.flush
    @db = IO.popen('rdebug -c','r+')
  end  
    
  test "enters debug mode" do
    expect = %{Connected.
(rdb:1) }
    assert_equal expect, wait_for_debugger
    @db.flush
  end
  
  test "lists function" do
    expect = %{Connected.
(rdb:1) l =
[1, 6] in /tmp/eval-4.rb
   1  
   2          lambda { |doc| 
   3            debugger;
=> 4            doc.size
   5            emit(doc)
   6          }
(rdb:1) }
    @db.puts 'l ='
    @db.flush
    assert_equal expect, wait_for_debugger
    @db.flush
  end
  
  test "steps through eval" do
    expect = %{Connected.
(rdb:1) s
(rdb:1) l =
[1, 6] in /tmp/eval-4.rb
   1  
   2          lambda { |doc| 
   3            debugger;
   4            doc.size
=> 5            emit(doc)
   6          }
(rdb:1) }
    @db.puts 's'
    @db.puts 'l ='
    @db.flush
    assert_equal expect,wait_for_debugger
    @db.flush
  end
  
  test 'sets breakpoints in eval' do
    expect = %{Connected.
(rdb:1) break 5
*** No source file named (eval)
Set breakpoint anyway? (y/n) y
Breakpoint 1 file (eval), line 5
(rdb:1) c
Breakpoint 1 at (eval):5
(rdb:1) l =
[1, 6] in /tmp/eval-4.rb
   1  
   2          lambda { |doc| 
   3            debugger;
   4            doc.size
=> 5            emit(doc)
   6          }
(rdb:1) }
    @db.puts 'break 5'
    @db.puts 'y'
    @db.puts 'c'
    @db.puts 'l ='
    assert_equal expect, wait_for_debugger
    @db.flush
  end
  
  teardown do
    @db.puts 'q'
    @db.puts 'y'
    @db.flush
    @db.close
    @vs.close
  end
  
end