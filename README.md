gs_cache
========

a caching proxy server run on local machine

run proxy.rb from command line and your proxy server will run on port 2000
pages are cached in cache.yaml. 

If the cache size plus the current incoming assets is more than 5000000 bytes ~= 5 megabytes,
the cache is emptied of the least recently used assets. The incoming page is then cached as usual.

run clear_cache.rb from the command line to empty the cache entirely.

To use the cache go to your proxies in network settings and set the IP field to 0.0.0.0 and the port field to 2000.
Chrome browser settings under advanced settings will get you there.
