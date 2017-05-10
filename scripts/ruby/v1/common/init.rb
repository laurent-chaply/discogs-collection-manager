OptionParser.new do |opts|
  opts.on("-u", "--username U") do |u|
    $username = u
  end
  opts.on("-t", "--token T") do |t|
    $user_token = t
  end
  opts.on("-s", "--csv-separator S") do |s|
    $csv_separator = s
  end
  opts.on("-l", "--log L") do |l|
    $log_file_name = l
  end
  opts.on("--log-reset") do
    $reset_log = true
  end
  opts.on("-c", "--cache C") do |c|
    $cache_file_name = c
  end
  opts.on("--flush-cache FC", [:all, :collection, :price]) do |fc|
    if fc == :all
      CACHE_LIST.each do |name|
        $flush_cache << name
      end
    else
      $flush_cache << fc
    end
  end
  opts.on("--no-cache") do
    $do_cache = false
  end
  parse_specific_options(opts)
end.parse!

initialize_log
script_banner
initialize_cache
initialize_discogs_wrapper
 