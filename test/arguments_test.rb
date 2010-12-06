require File.dirname(__FILE__) + '/test_helper'
f_dir = File.dirname(__FILE__).split('/')[0..-2].push('bin').join('/')


context "arguments should be processed correctly" do
    
  test 'debug arguments are ignored if in safe mode' do
    ARGV << '--debug'
    load f_dir+'/couchdb_view_server'
    assert_nil CouchDB.debug
    assert CouchDB::Sandbox.safe
  end
  
  test 'functions can access required files' do
    ARGV << '-r active_support'
    load f_dir+'/couchdb_view_server'
    CouchDB.run ["add_fun", "lambda{|doc| emit('this_is_a_test/okay'.camelize,nil) }"]
    r = CouchDB.run ["map_doc","{'_id':'foo'}"]
    assert_equal [[['ThisIsATest::Okay',nil]]], r
  end
  
end
