require 'net/http'
require 'debugger'
require 'socket'
require 'yaml'
require 'thread'


class Proxy

  def run(port)
    @semaphore = Mutex.new
    
    begin
      begin
        @cache = YAML.load_file('cache.yaml') || {}
        rescue
        @cache = {}
      end
      @cache_file = File.open('cache.yaml','w') 
      p @cache.keys
      p port
      @proxy_server = TCPServer.new port
      p @proxy_server
      loop {
        Thread.new (@proxy_server.accept) do |request|
          handle_request request
        end
      }
    ensure
      p @cache.keys
      YAML.dump(@cache, @cache_file)
      @cache_file.close()
    end
  end
  
  def handle_request(to_client)
    res_body = get_response(to_client)
    
    to_client.write(res_body)  #write body to client
        
    to_client.close
    http.close
  end

  def get_response(to_client)
    line1 = to_client.readline
    parts = line1.split(' ')
    verb = parts[0].downcase
    url = parts[1]
    
    if @cache[url]
      p 'cache hit'
      p url
      return @cache[url]
    end
    
    uri = URI::parse url
    
    p uri.host, uri.path
        
    http = Net::HTTP.new(uri.host)          # Create a connection
    res = http.send(verb, uri.path)     # Request the file
    res_body = res.read_body
    p url
    @cache[url] = res_body
    p @cache.keys

    manage_cache 
    
    return res_body

  end
  
  def manage_cache
    p 'cache miss'
    semaphore.syncronize{YAML.dump(@cache, @cache_file)}
    
    p File.size?(@cache_file).to_f / 1024000   
  end


  
 
end

Proxy.new.run 2000