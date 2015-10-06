require_relative "common/common"

def parse_specific_options(opts)
  # TODO add options for directories
end

require_relative "common/init"

def check_discogs_id3(track) 
  TagLib::MPEG::File.open(track) do |file|
    other_discogs_frames = file.id3v2_tag.frame_list.select { |frame| 
      frame.is_a?(TagLib::ID3v2::UserTextIdentificationFrame) and
      frame.description.downcase == "discogs_release_id"
    }.each do |frame|
      release_id = frame.field_list[1]
      if $collection.has_key?(release_id)
        $ok[release_id] = $collection[release_id]
      else
        $ko[release_id] = $collection[release_id]
      end
    end
  end
end

$collection = {}
$cache[:collection].each do |k, collection_page|
  collection_page.releases.each do |release|
    $collection[release.id] = release
  end
end
$ok = {}
$ko = {}

# iterate_music_dir("#{base_dir_hq}/#{$music_dir}", /.*\.(flac)$/) do |track|
#   check_discogs_flac(track)
# end
iterate_collection_dir("#{$collection_dir_sq}/#{$collection_basen_dir}", /.*\.(mp3)$/) do |track|
  check_discogs_id3(track)
end

puts "*** OK #{$ok.size}"
puts $ok.keys
puts "*** KO #{$ko.size}"
puts $ko.keys
