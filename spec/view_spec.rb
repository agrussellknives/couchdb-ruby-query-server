require_relative '../lib/couchdb_view_server'

# i think i'm going ot leave this for now.
# i want ot define m/r as a class, which is going
# to require rewriting the worker, so let's just hodl off on this.
describe "adding map functions" do
  before do
    CouchDB.start ViewServer
  end
end
