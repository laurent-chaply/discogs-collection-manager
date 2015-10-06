require 'itunes_parser'
require_relative "common/common"

# Options
$itunes_library = "#{Dir.home}/Music/iTunes/iTunes Music Library.xml"
$lookup_dir = "#{$collection_dir_sq}/#{$collection_base_dir}"
$output_file_name = "itunes-ratings.csv"
$output_file_mode = "w"
$filter_regexp = /^file\:\/\/(localhost)?#{Regexp.escape($lookup_dir)}\/(([^\/]+)\/\[[^\]]+\] ?\[([^\]]+)\] ([^\/]+))\/([^ ]+) \-/

def parse_specific_options(opts)
  opts.on("-i", "--itunes-library i", Integer) do |i|
    $itunes_library = i
  end
  opts.on("-d", "--dir d", Integer) do |d|
    $lookup_dir = d
  end
  opts.on("-o", "--output O") do |o|
    $output_file_name = o
  end
end

class RatingInfo
  attr_reader :file_path, :label, :catno, :detail
  def initialize(file_path, label, catno)
    @file_path = file_path
    @label = label
    @catno = catno
    @detail = RatingInfoDetail.new(self)
  end
end

class RatingInfoDetail
  attr_reader :top_track, :tracks
  def initialize(info)
    @info = info
    @tracks = 0
    @track_ratings = {}
    @actual_ratings = {}
    @top_track = false
  end
  def add_track_rating(trackno, rating)
    if @track_ratings.key?(trackno)
      $logger.warn("Duplicate entry #{@info.file_path} - #{trackno}")
    else
      @tracks += 1
      @track_ratings[trackno] = nil
    end
    if !rating.unset?
      @track_ratings[trackno] = rating
      @actual_ratings[trackno] = rating
      if rating.top?
        @top_track = true
      end
    end
  end
  def rating_count
    return @actual_ratings.size
  end
  def avg_rating
    total = 0
    @actual_ratings.values.each do |rating|
      total += rating.value
    end
    if total == 0
      return 0
    else
      return total / rating_count
    end
  end
  def rating_list
    rating_list = []
    @actual_ratings.values.each do |rating|
      rating_list << rating.value
    end
    return rating_list
  end
end

class Rating
  def initialize(value = 0, loved = false)
    @value = value
    @loved = loved
  end
  def unset?
    return value.nil? || value == 0
  end
  def top?
    return @loved || @value == 100
  end
  def value
    value = @value
    if @loved
      value += 10
    end
    return value
  end
end

def update_rating(file_path, label, catno, trackno, rating, loved)
  rating_info = $ratings[file_path]
  if rating_info.nil?
    rating_info = RatingInfo.new(file_path, label, catno)
    $ratings[file_path] = rating_info
  end
  rating_info.detail.add_track_rating(trackno, Rating.new(rating, loved))
end

require_relative "common/init"

# Collect rating info

$ratings = {}
parser = ItunesParser.new(open($itunes_library) )
parser.tracks.each do |track|
  location = track["Location"]
  rating = track["Rating"]
  loved = track["Loved"]
  if !location.nil?
    location = URI.unescape(location)
    if result = location.match($filter_regexp)
      release_file_path, label, catno, title, trackno = result.captures[1..-1]
      update_rating(release_file_path, label, catno, trackno, rating.to_i, loved)
    end
  end
end

# Write it to csv

$out = File.new("#{$export_dir}/#{$output_file_name}", "#{$output_file_mode}")

header = ["Release path", "Rtg complete", "Top", "Avg rtg", "Rtg status", "Rtg detail"]
$out.write(header.join($csv_separator) + "\n")

# post process ratings by album
$ratings.each do |k, rating_info|
  rating_count = rating_info.detail.rating_count
  if rating_count > 0
    # Path
    rating_info_line = [rating_info.file_path]
    # Complete
    track_count = rating_info.detail.tracks
    rating_complete = $csv_no
    if rating_count == track_count
      rating_complete = $csv_yes
    end
    rating_info_line << rating_complete
    # Top
    top = $csv_no
    if rating_info.detail.top_track
      top = $csv_yes
    end
    rating_info_line << top
    # Avg
    rating_info_line << rating_info.detail.avg_rating
    # Status
    rating_info_line << "#{rating_count} of #{track_count}"
    # Detail
    rating_info_line << rating_info.detail.rating_list.join("|")
    $out.write(rating_info_line.join($csv_separator) + "\n")
  end
end