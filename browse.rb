require 'net/http'                  # The library we need
host = 'crododile.github.io'     # The web server
path = '/'                 # The file we want 

http = Net::HTTP.new(host)          # Create a connection
p http.get(path).body      # Request the file
