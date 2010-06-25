# CouchDB Ruby Query Server

by Matthew Lyon <matt@flowerpowered.com>

This is a ruby version of the CouchDB Query server. It will let you write your
map and reduce functions in ruby (instead of javascript, erlang, or what have
you) and eventually all your couchapp functions as well.

It is still very much a work in progress, please don't use it for anything in
production yet. 

## Usage

In one of your CouchDB config files, add this:

    [query_servers]
    ruby = /path/to/ruby /path/to/bin/couchdb_view_server

If you want to just use environment ruby you can leave /path/to/ruby out.

Your design documents should look something like this:

    {
        "_id": "_design/foos",
        "language": "ruby",
        "views": {
            "foos": {
                "map": "lambda{|doc| emit(doc['foo'], nil) }"
            }
        }
    }
 
By default, all code run within the view server is sandboxed. So that you can 
allow people you may not necessarily trust "admin-level" access to your CouchDB
install, such that they may create design documents and therefore upload their
own code.  Certain features of the view server, such as debugging and logging
errors to a file are not available unless the server is explicity run in --unsafe
mode.

All code is eval'd and run under a `$SAFE` level of 4 in this mode. If running
in safe mode, it is preferred to run under Ruby 1.9, which has a vastly
improved "trust/untrusted" model for security of objects.

If you do want to run your views in unsafe mode flag like so:

    [query_servers]
    ruby = /path/to/ruby -- /path/to/bin/couchdb_view_server --unsafe
    

## Debugging

It is possible to attach rdebug to the query server to debug the map, etc.
functions as they are being run.  This requires the Ruby 1.9 compatible 
ruby-debug gem.  The view server uses a specially patched version of the
debugger in order to allow you to list, step through, and set breakpoints within
eval'd lambda functions.

In order for the debugger to attach, you must start the view server with at 
least both the --unsafe and the --debug options.  The following options are also
available.

Usage: add the path of the couchdb_view_server in your couchdb.ini file, and
specify options there.

**Using any of the debug settings will slow the view server down considerably.**

Specific Options:
    -f, --file FILENAME              Output STDERR to file FILENAME. Ignored if
 									 --debug and --unsafe are not given
    -u, --debug                      Enable debugging of Query Server Functions. 
 									 	Ignored if --unsafe is not given.
    -s, --stop-on-error              Wait for a debugger to connect if an 
										exception is thrown.  Ignored if --debug
										is not given
    -w, --wait                       Wait for debugger connection on startup. 
										Ignored if --debug is not given.
        --unsafe                     Don't sandbox Query Server Functions. 
										DANGEROUS.
    -r FILE                          require a file into the view server 
										so it can be accessed within functions
    -h, --help                       Display this screen


## Requiring External Libraries

Passing a -r FILE to the view server will require the file into the view server,
so functions, constants, etc within it will be available to eval'd view functions.

Requiring a file is done each time the server is executed (which can be frequently)
so requiring large libraries may not be very wise.

## Notes

Does not yet run on Ruby 1.8.6, as it requires `instance_exec`. Will most
likely just steal Rails' implementation.

## TODO

* improve safe mode support by redefining Kernel#sleep to raise.
* improve start up time of server

## Maybe/Someday TODO Wishlist

* implement `Object#instance_exec` so this can run on Ruby 1.8.6
* implement some sort of proper template system for show/list. Would likely go
  with Mustache. OTOH, there's nothing stopping you from doing this inside
  show/list yourself.

## Changelog

### 0.8 2010-04-11
* implement `log` and `throw` methods across all proc runners
* make the design doc available to all design doc functions (basically,
  everything except map and reduce) (thanks, jchris)
* fixed a problem in list functions where returning a send function crashed
  (thanks jchris)

### 0.2 2010-03-25
* round out support for all function types, including `validate_doc_update`,
  `update`, `show` and `list`.

### 0.1.2 2010-03-14
* fix for multiple reduce functions being run simultaneously

### 0.1.1 2010-03-14
* README updates, gem version bump

### 0.1 2010-03-14
* Offer a "safe" flag to provide a locked-down sandbox for user code inside
  $SAFE level 4.

### 0.1pre 2 2010-03-13
* Consolidate a lot of the "in-place, get it working" code for map/reduce to
  the View module.

### 0.1pre 1 2010-03-07
* Basic implementation of map/reduce working.
