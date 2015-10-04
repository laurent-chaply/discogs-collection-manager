require_relative "common/common"

$lookup_dir = "/Volumes/Portable Archive 1 1/Music"
$output_file_name = "beatport-info.csv"
$output_file_mode = "w"

def parse_specific_options(opts)
  opts.on("-d", "--dir D") do |d|
    $release_dir = d
  end
end
require_relative "common/init"

def get_beatport_info(track)
  TagLib::MPEG::File.open(track) do |file|
    ids = file.id3v2_tag.frame_list.select { |frame|
      frame.is_a?(TagLib::ID3v2::UniqueFileIdentifierFrame)
    }
    if ids.size > 0
      return {
        :id => ids[0].identifier,
        :track => file.id3v2_tag.track,
        :title => file.id3v2_tag.title,
      }
    end
  end
  return false
end

def check_release(release_dir)
  track_count = 0
  beatport_count = 0
  beatport_links = []
  iterate_files(release_dir, /.*\.(mp3)$/) do |track|
    track_count += 1
    if beatport_info = get_beatport_info(track)
      beatport_count += 1
      id = beatport_info[:id].split("-").last
      beatport_links << "\"=HYPERLINK(\"\"https://pro.beatport.com/track/x/#{id}\"\";\"\"#{beatport_info[:track]} - #{beatport_info[:title]}\"\")\""
    end
  end
  $logger.info("#{release_dir} > #{beatport_count} tracks of #{track_count} have beatport id")
  if beatport_count > 0
    release_dir.slice!("#{$lookup_dir}/")
    csv_line = ["\"#{release_dir}\""]
    if beatport_count == track_count
      csv_line << $csv_yes
    else
      csv_line << $csv_no
    end
    csv_line << "#{beatport_count} of #{track_count}"
    csv_line += beatport_links
    $out.write(csv_line.join($csv_separator) + "\n")
  end
end

$out = File.new("#{$export_dir}/#{$output_file_name}", "#{$output_file_mode}")

header = ["Release path", "Beatport", "Detail"]
$out.write(header.join($csv_separator) + "\n")

iterate_collection_releases($lookup_dir) do |release|
  check_release(release)
end