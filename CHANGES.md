0.17.3 (2016-01-18)
-----
* [#163](https://github.com/celluloid/celluloid-io/pull/163)
  Support Ruby 2.3.0.

* [#162](https://github.com/celluloid/celluloid-io/pull/162)
  Fix broken specs.

* [#160](https://github.com/celluloid/celluloid-io/pull/160)
  Use a common super class for all socket wrappers.
  ([@hannesg])

* [#159](https://github.com/celluloid/celluloid-io/pull/159)
  UNIXSocket: don't delegate #readline and #puts.
  ([@hannesg])

* [#158](https://github.com/celluloid/celluloid-io/pull/158)
  Use unix sockets in unix spec instead of tcp sockets.
  ([@hannesg])

* [#157](https://github.com/celluloid/celluloid-io/pull/157)
  Stream#close is not called in subclasses.
  ([@hannesg])

* [#155](https://github.com/celluloid/celluloid-io/pull/155)
  Only close Selector it not already closed.

* [#98](https://github.com/celluloid/celluloid-io/pull/98)
  Added spec for writing later to a socket within a request/response cycle
  using the timer primitives.
  ([@TiagoCardoso1983])

0.17.2 (2015-09-30)
-----
* Revamped test suite, using shared RSpec configuration layer provided by Celluloid itself.
* Updated gem dependencies provided by Celluloid::Sync... extraneous gems removed, or marked as development dependencies.

0.17.1 (2015-08-24)
-----
* Minor bug fixes. Synchronize gem dependencies.

0.17.0 (2015-08-07)
-----
* Compatibility with Celluloid 0.17.0+
* Adjust class name for Celluloid::Mailbox::Evented, per 0.17.0 of Celluloid.

0.16.2 (2015-01-30)
-----
* More TCPSocket compatibility fixes
* Ensure monitors are closed when tasks resume
* Fix Errno::EAGAIN handling in Stream#syswrite

0.16.1 (2014-10-08)
-----
* Revert read/write interest patch as it caused file descriptor leaks

0.16.0 (2014-09-04)
-----
* Fix bug handling simultaneous read/write interests
* Use Resolv::DNS::Config to obtain nameservers
* Celluloid::IO.copy_stream support (uses a background thread)

0.15.0 (2013-09-04)
-----
* Improved DNS resolver with less NIH and more Ruby stdlib goodness
* Better match Ruby stdlib TCPServer API
* Add missing #send and #recv on Celluloid::IO::TCPSocket
* Add missing #setsockopt method on Celluloid::IO::TCPServer
* Add missing #peeraddr method on Celluloid::IO::SSLSocket

0.14.0 (2013-05-07)
-----
* Add `close_read`/`close_write` delegates for rack-hijack support
* Depend on EventedMailbox from core

0.13.1
-----
* Remove overhead for `wait_readable`/`wait_writable`

0.13.0
-----
* Support for many, many more IO methods, particularly line-oriented
  methods like #gets, #readline, and #readlines
* Initial SSL support via Celluloid::IO::SSLSocket and
  Celluloid::IO::SSLServer
* Concurrent writes between tasks of the same actor are now coordinated
  using Celluloid::Conditions instead of signals
* Celluloid 0.13 compatibility fixes

0.12.0
-----
* Tracking release for Celluloid 0.12.0

0.11.0
-----
* "Unofficial" SSL support (via nio4r 0.4.0)

0.10.0
-----
* Read/write operations are now atomic across tasks
* True non-blocking connect support
* Non-blocking DNS resolution support

0.9.0
-----
* TCPServer, TCPSocket, and UDPSocket classes in Celluloid::IO namespace
  with both evented and blocking I/O support
* Celluloid::IO::Mailbox.new now takes a single parameter to specify an
  alternative reactor (e.g. Celluloid::ZMQ::Reactor)

0.8.0
-----
* Switch to nio4r-based reactor
* Compatibility with Celluloid 0.8.0 API changes

0.7.0
-----
* Initial release forked from Celluloid

[@TiagoCardoso1983]: https://github.com/TiagoCardoso1983
[@hannesg]: https://github.com/hannesg
