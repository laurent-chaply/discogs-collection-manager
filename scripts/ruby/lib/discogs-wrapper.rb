require "discogs"

module DiscogsWrapper
  
  @@app_name = config.discogs.app_name
  @@user_name = config.discogs.user_name
  @@user_token = config.discogs.user_token
  
  #
  # Initialization
  #
  
  def self.parse_options(opts)
  end
  
  def self.init
    @@wrapper = Discogs::Wrapper.new(@@app_name, user_token: @@user_token)
  end
  
  #
  # Functions
  # 
  
  def self.call(*params)
    fname = params[0]
    fparams = params[1..-1]
    cached = false
    if CacheManager.enabled?
      result = CacheManager.get(fname, fparams)
    end
    if result.nil?
      sleep config.discogs.wait_time
      result = @@wrapper.send(fname, *fparams)
      if CacheManager.enabled?
        CacheManager.put(fname, fparams, result)
      end
    else
      cached = true
    end
    return result, cached
  end
  
end