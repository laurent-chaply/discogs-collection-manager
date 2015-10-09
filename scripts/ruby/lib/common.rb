require "optparse"
require "pry"
require "open3"
require "stringex_lite"

CONFIG_NAME = "default"
require_relative "configuration"

require_relative "logging"
require_relative "cache"
require_relative "discogs-wrapper"

require_relative "discogs-utils"

def parse_options(&block)
  OptionParser.new do |opts|
    Logging.parse_options(opts)
    CacheManager.parse_options(opts)
    DiscogsWrapper.parse_options(opts)
    if !block.nil?
      block.call(opts)
    end
  end.parse!
end

def init(&block)
  Logging.init
  CacheManager.init
  DiscogsWrapper.init
  if !block.nil?
    block.call
  end
end
