require "yell"

module Logging
  @@log_dir = "#{config.default_work_dir}/log"
  @@log_name = $PROGRAM_NAME.sub("rb", "log")
  @@log_reset = config.log.reset
  
  #
  # Initialisation
  #
  
  def self.parse_options(opts)
    opts.on("-l", "--log L") do |l|
      @@log_name = l
    end
    opts.on("--log-reset") do
      @@log_reset = true
    end
  end
  
  def self.init
    log_file = File.join(@@log_dir, @@log_name)
    if @@log_reset && File.exists?(log_file)
      File.delete(log_file)
    end
    
    # Yell init
    levels = [:info, :warn, :error, :fatal]
    Yell.new :file, log_file, name: Object, :format => Yell.format("[%d][%L][%f:%M:%n] %m", "%Y-%m-%d %H:%M:%S:%3N"), :trace => levels, :level => levels
    Object.send(:include, Yell::Loggable)
    
    # Banner
    logger.info ""
    logger.info "***********************************"
    logger.info "**** " + config.app_name
    logger.info "***********************************"
    logger.info ""
  end

end
