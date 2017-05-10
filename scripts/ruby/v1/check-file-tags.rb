require_relative "common/common"

$lookup_dir = "#{$collection_dir_hq}/#{$collection_base_dir}"
$output_file_name = "release-status-from-tags.csv"
$output_file_mode = "w"

$digital_online_map = {
  "Vynil - Available on Beatport" => "beatport",
  "Vynil - Available on Juno" => "juno",
  "Vynil - No Digital Release" => "none"
}
$selling_status_map = {
  "Vynil - Sell OK" => 1,
  "Vynil - Keep" => 0
}

def parse_specific_options(opts)
end

require_relative "common/init"

$out = File.new("#{$export_dir}/#{$output_file_name}", "#{$output_file_mode}")

header = ["Release path", "Digital online", "Digital ver. on", "Selling"]
$out.write(header.join($csv_separator) + "\n")

iterate_collection_releases($lookup_dir) do |release|
  stdin, stdout = Open3.popen2e("tag", "-lN", release)
  result = []
  tags = nil
  stdout.readlines.each do |line|
    tags = line.strip.split(",")
  end
  if !tags.nil?
    release.slice!("#{$lookup_dir}/")
    csv_line = [release]
    dig_ver_on = nil
    selling = nil
    tags.each do |tag|
      if dig_ver_on.nil?
        dig_ver_on = $digital_online_map[tag]
      end
      if selling.nil?
        selling = $selling_status_map[tag]
      end
    end
    dig_online = nil
    if !dig_ver_on.nil?
      if dig_ver_on == "none"
        dig_online = $csv_no
      else
        dig_online = $csv_yes
      end
    else
      dig_online = $csv_no_value
    end
    if selling.nil?
      selling = $csv_no_value
    end
    csv_line << dig_online
    csv_line << dig_ver_on
    csv_line << selling
    $out.write(csv_line.join($csv_separator) + "\n") 
  end
end