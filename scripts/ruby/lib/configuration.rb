require_relative "../config/#{CONFIG_NAME}"

# global configuration
module Configurable
  def config
    return Configuration.for(CONFIG_NAME)
  end
end
Object.send(:include, Configurable)
