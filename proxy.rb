require 'net/http'
require 'debugger'
require 'socket'

class Proxy
  def run(port)
    begin
      p port
      @proxy_server = TCPServer.new port
      p @proxy_server
      loop {
        Thread.new (@proxy_server.accept) do |request|
          p '_____new_request_____'
          handle_request request
        end
      }
    end
  end
  
  def handle_request(to_client)
    
    line1 = to_client.readline
    parts = line1.split(' ')
    verb = parts[0].downcase
    url = parts[1]
    version = parts[2]
    uri = URI::parse url
    
    p uri.host, uri.path
        
    http = Net::HTTP.new(uri.host)          # Create a connection
    res = http.send(verb, uri.path)      # Request the file
    
    to_client.write(res.read_body)
    
    to_client.close
    http.close
   
  end
 
end

Proxy.new.run 2000