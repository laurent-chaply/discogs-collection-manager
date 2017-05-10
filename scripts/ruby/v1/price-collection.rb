require_relative "common/common"

# Options
$folder_id = DEFAULT_FOLDER_ID
$output_file_name = "collection.csv"
$output_file_mode = "w"

def parse_specific_options(opts)
  opts.on("-f", "--folder F", Integer) do |f|
    $folder_id = f
  end
  opts.on("-o", "--output O") do |o|
    $output_file_name = o
  end
  opts.on("-s", "--csv-separator S") do |s|
    $csv_separator = s
  end
  opts.on("-i", "--items I", Integer) do |i|
    $items = i
  end
  opts.on("-p", "--page P", Integer) do |p|
    $start_page = p
    $output_file_mode = "a"
  end
end

def dump_price(releases)
  releases.each do |release|
    if is_vinyl?(release)
      priceinfo = nil
      cached = false
      if $do_cache
        priceinfo = $cache[:price][release.id]
      end
      if priceinfo.nil?
        sleep 1.2
        priceinfo = $wrapper.get_price_suggestions(release.id)
        if $do_cache
          $cache[:price][release.id] = priceinfo
        end
      else
        cached = true
      end
      prices = []
      ITEM_CONDITIONS.each_value do |condition|
        price = priceinfo[condition]
        value = 0
        if !price.nil?
          # value = price.value.to_s.sub(".", $float_separator) 
          value = price.value 
        end
        prices.push(value)
      end
      $logger.info(collection_release_to_str(release) + " = (VG) #{prices[0]} (#{cached})")
      $out.write(csv_line(release, prices))
    else
      $logger.warn(collection_release_to_str(release) + " X non Vinyl")
    end
  end
end

def csv_line(release, prices)
  release_info = collection_release_basics(release)
  release_info.insert(1, release.instance_id)
  release_info += prices
  return release_info.join($csv_separator) + "\n"
end

require_relative "common/init"

$out = File.new("#{$export_dir}/#{$output_file_name}", "#{$output_file_mode}")

# Start

$logger.info(" > #{$username}'s collection / folder #{$folder_id}")
$logger.info(" > starting from page #{$start_page}")
$logger.info(" > CSV file : " + $output_file_name)

header_info = ["Discogs ID", "Instance ID", "Label", "Catalog #", "Artist(s)", "Title"]
ITEM_CONDITIONS.each_key do |condition|
  header_info << condition
end
$out.write(header_info.join($csv_separator) + "\n")

page = $start_page
pages = page
while page <= pages
  cache_key = "collection-folder-#{$folder_id}-by-#{$items}-page-#{page}"
  collection = nil
  cached = false
  if $do_cache
    collection = $cache[:collection][cache_key]
  end
  if collection.nil?
    collection = $wrapper.get_user_folder_releases($username, $folder_id, :page => page, :per_page => $items)
    if $do_cache
      $cache[:collection][cache_key] = collection
    end
  else
    cached = true
  end
  pages = collection.pagination.pages
  $logger.info("")
  $logger.info("* PAGE #{page} of #{pages} (#{cached})")
  $logger.info("")
  dump_price(collection.releases)
  page += 1
end
