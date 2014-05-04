require 'net/http'
require 'socket'
require 'yaml'



class Proxy

  def run(port)
    # Thread.abort_on_exception = true  COMMENTED OUT TO PREVENT CRASHING, IS USEFUL AT TIMES
    begin
      begin
        @cache = YAML.load_file('cache.yaml') || {}  #Cache loaded into memory
        rescue
        @cache = {}
      end
      begin
        @times = YAML.load_file('times.yaml') || {}  #Access times for lru clearing loaded in
        rescue
        @times = {}
      end
      if File.file?("size.txt") #holds byte size of cached data
        File.open('size.txt','r'){ |f|
          @count = f.read.to_i
          } 
      else 
        File.open('size.txt','w+'){ |f| #create file if it doesnt exist
          @count = f.read.to_f
          }
      end   
      @proxy_server = TCPServer.new port
      p " proxy cache runnning on " + port.to_s
      loop {
        Thread.new (@proxy_server.accept) do |request|
          handle_request request
        end
      }
    rescue Exception => e
      p e
      puts "EXCEPTION: #{e.inspect}"
      puts "MESSAGE: #{e.message}" 
      
    ensure #WRITE TO FILES PRESENT STATE OF CACHE ON CLOSING
      @times_file = File.open('times.yaml','w') 
      YAML.dump(@times, @times_file)
      @times_file.close()    
      @cache_file = File.open('cache.yaml','w') 
      YAML.dump(@cache, @cache_file)
      @cache_file.close()
      File.open('size.txt','w+'){ |f|
        p 'writing'
        p @count
        f.syswrite(@count)
      }
    end
  end
  
  def handle_request(to_client)
    res_body = get_response(to_client)
    to_client.write(res_body)
    to_client.close
  end

  def get_response(to_client)
    line1 = to_client.readline
    parts = line1.split(' ')
    verb = parts[0].downcase
    url = parts[1]
   
    if @cache[url]
      @times[url] = Time.now
      p url
      p 'cache hit!'
      return @cache[url]
    end
    uri = URI::parse url  
    # this host breaks the cache when we try to remove it, don't put it in..response too large?
    return if uri.host == "www.google-analytics.com"
    # not interested in these verbs
    return if verb == 'connect' || verb == 'post'
    
    @times[url] = Time.now
    http = Net::HTTP.new(uri.host)  
    res = http.send(verb, uri.request_uri)     
    res_body = res.read_body
    p url  

    manage_cache(res.body.length)
    @cache[url] = res_body
    p 'cached '+ url
    @count += res_body.length 

    return res_body
  end
  
  def manage_cache(incoming)
    while @count > 5000000 - incoming
        p 'cache too full'
        to_remove = @times.key(@times.values.min)
        @times.delete(to_remove)
        p "removing " + to_remove
        @count -= @cache[to_remove].length
        p @count
        @cache.delete(to_remove)
   end    
  end
 
end

Proxy.new.run 2000