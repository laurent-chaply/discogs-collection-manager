require "persistent-cache"

class Cache
  attr_accessor :enabled, :flush_all, :flush_list
  
  def initialize
    @cache_dir = "#{DEFAULT_WORK_DIR}/cache2"
    @flush_all = false
    @enabled = true
    @flush_list = []
    @cache = {}
  end
  
  def initialize_cache(name)
   $logger.info(" > Caching #{name} enabled")
   cache_file = "#{@cache_dir}/#{name}.cache"
   if self.flush?(name) && File.exists?(cache_file)
     $logger.warn(" > Flushing cache #{name}")
     File.delete(cache_file)
   end
   @cache[name] = Persistent::Cache.new(cache_file, nil)
  end
  
  def ensure_cache(name)
    if !@cache.has_key?(name)
      initialize_cache(name)
    end
  end
  
  def enable
    @enabled = true
  end
  
  def disable
    @enabled = false
  end
  
  def put(name, key, value)
    ensure_cache(name)
    @cache[name][key] = value
  end
  
  def get(name, key)
    ensure_cache(name)
    return @cache[name][key]
  end
  
  def flush?(name)
    puts "#{@flush_all}"
    puts "#{@flush_list}"
    puts name
    puts ""
    return @flush_all || @flush_list.include?(name)
  end
end