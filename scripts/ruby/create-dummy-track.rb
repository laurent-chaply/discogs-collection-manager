require_relative "common/common"

$base_track = "/Volumes/Media/Downloads/Test/dummy.mp3"
$outdir = "/Volumes/Media/Downloads/Test/Music-dummy"
$ids_file = "#{$export_dir}/no-digital-local-ids.txt"

def parse_specific_options(opts)
  opts.on("-d", "--discogs-id ID", Integer) do |id|
    $discogs_id = id
  end
end

require_relative "common/init"

frame_factory = TagLib::ID3v2::FrameFactory.instance
frame_factory.default_text_encoding = TagLib::String::UTF8

def add_id3v2_tag(tag, key, value)
  frame = TagLib::ID3v2::TextIdentificationFrame.new(key, TagLib::String::UTF8)
  frame.text = value
  tag.add_frame(frame)
end

def add_user_id3v2_tag(tag, key, value)
  frame = TagLib::ID3v2::UserTextIdentificationFrame.new(TagLib::String::UTF8)
  frame.description = key
  frame.text = value.to_s
  tag.add_frame(frame)
end

def file_friendly(str)
  return str.gsub("/",":")
end

def create_dummy_release(discogs_id)
  release = $wrapper.get_release(discogs_id)
  label = release.labels[0].name
  catno = release.labels[0].catno
  release_artists = release.artists
  release_title = release.title
  release_date = release.released
  release_subdir = "#{label}/[#{catno}][#{discogs_id}] #{file_friendly(artists_to_str2(release_artists))} - #{file_friendly(release_title)}"
  release_dir = "#{$outdir}/#{release_subdir}"
  $logger.info("Creating dummy release #{release_subdir}")
  if File.exists?(release_dir)
    $logger.warn(">> already exists - skipping")
    return false
  end
  FileUtils.makedirs(release_dir)
  # first pass for tracks
  release.tracklist.each_index do |idx|
    track = release.tracklist[idx]
    num = track.position
    artists = track.artists
    if artists.nil?
      artists = release_artists
    end
    title = track.title
    trackfile = "#{release_dir}/#{num} - #{file_friendly(artists_to_str2(artists))} - #{file_friendly(title)}.mp3"
    FileUtils.copy($base_track, trackfile)
    # Create tags  
    TagLib::MPEG::File.open(trackfile) do |file|
      tag = file.id3v2_tag
      tag.artist = artists_to_str2(artists)
      tag.title = title
      tag.album = release_title
      tag.track = idx+1
      add_id3v2_tag(tag, "TPUB", label)
      add_id3v2_tag(tag, "TDRL", release_date)
      add_user_id3v2_tag(tag, "DISCOGS_RELEASE_ID", discogs_id)
      file.save
    end
  end
  return true
end

if !$discogs_id.nil?
  create_dummy_release($discogs_id)
else
  File.open($ids_file).readlines.each do |line|
    puts line.strip
    create_dummy_release(line.strip)
    sleep 1
  end
end
