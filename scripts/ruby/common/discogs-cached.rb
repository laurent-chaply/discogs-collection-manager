require "discogs"

class CachedWrapper
  def initialize(app_name, user_token, cache)
    @cache = cache
    @wrapper = Discogs::Wrapper.new(app_name, user_token: user_token)
  end
  
  def call(*params)
    fname = params[0]
    fparams = params[1..-1]
    cached = false
    if @cache.enabled
      result = @cache.get(fname, fparams)
    end
    if result.nil?
      sleep 1.2
      result = @wrapper.send(fname, *fparams)
      if @cache.enabled
        @cache.put(fname, fparams, result)
      end
    else
      cached = true
    end
    return result, cached
  end
end