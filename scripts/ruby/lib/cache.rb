require "persistent-cache"

module CacheManager
  ALL_CACHE = "all"
  CACHE_DIR = "cache"
  
  @@cache_dir = File.join(config.default_work_dir, CACHE_DIR)
  FileUtils.mkdir_p(@@cache_dir)
  @@flush_all = false
  @@enabled = true
  @@flush_list = []
  @@cache = {}

  #
  # Initialization
  #

  def self.parse_options(opts)
    opts.on("--flush-cache FC") do |fc|
      if fc == ALL_CACHE
        @@flush_all = true
      else
        @@flush_list << fc
      end
    end
    opts.on("--no-cache") do
      @@enabled = false
    end
  end
  
  def self.init
  end
  
  #
  # Functions
  #
  
  def self.get(name, key)
    ensure_cache(name)
    return @@cache[name].get(key)
  end
  
  def self.put(name, key, value)
    ensure_cache(name)
    @@cache[name].put(key, value)
  end
  
  def self.ensure_cache(name)
    if !@@cache.has_key?(name)
      @@cache[name] = Cache.new(name, File.join(@@cache_dir, "#{name}.cache"), self.flush?(name))
    end
  end
  
  def self.enabled?
    return @@enabled
  end
  
  def self.flush?(name)
    return @@flush_all || @@flush_list.include?(name)
  end
  
  #
  # Classes
  #
  
  class Cache
    def initialize(name, cache_file, flush)
      logger.info(" > Caching #{name} enabled")
      if flush && File.exists?(cache_file)
        logger.warn(" > Flushing cache #{name}")
        File.delete(cache_file)
      end
      @cache = Persistent::Cache.new(cache_file, nil)
    end
    def put(key, value)
      @cache[key] = value
    end
    def get(key)
      return @cache[key]
    end
  end
  
end
