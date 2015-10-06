require_relative "common/common"
require "writeexcel"

$lookup_dir = "/Volumes/Portable Archive 1 1/Music"
$output_file_name = "beatport-info.xls"
$output_file_mode = "w"

def parse_specific_options(opts)
  opts.on("-d", "--dir D") do |d|
    $release_dir = d
  end
end
require_relative "common/init"

class Track
  attr_reader :label, :artists, :release, :title, :beatport_id
  def initialize(track_file)
    TagLib::MPEG::File.open(track_file) do |file|
      @label = file.id3v2_tag.frame_list.select { |f| f.frame_id == "TPUB" }.first.to_s
      @artists = file.id3v2_tag.artist
      @release = file.id3v2_tag.album
      @title = file.id3v2_tag.title
      ids = file.id3v2_tag.frame_list.select { |frame|
        frame.is_a?(TagLib::ID3v2::UniqueFileIdentifierFrame)
      }
      if ids.size > 0
        @beatport_id = ids.first.identifier.split("-").last
      end
    end
  end
end

def check_release(release_dir)
  track_count = 0
  beatport_count = 0
  tracks = []
  iterate_files(release_dir, /.*\.(mp3)$/) do |track_file|
    track_count += 1
    track = Track.new(track_file)
    tracks << track
    if !track.beatport_id.nil?
      beatport_count += 1
    end
  end
  release_dir.slice!("#{$lookup_dir}/")
  if beatport_count > 0
    tracks.each_index do |i|
      track = tracks[i]
      $row_num += 1
      if i == 0
        row = [release_dir, beatport_count == track_count ? $csv_yes : $csv_no, "#{beatport_count} of #{track_count}"]
        $sheet.write_row($row_num, 0, row, beatport_count == track_count ? nil : $format_red)
      end
      format = track.beatport_id.nil? ? $format_red : nil
      $sheet.write($row_num, 3, track.label, format)
      $sheet.write($row_num, 4, track.release, format)
      track_name = "#{i + 1} - #{track.artists} - #{track.title}"
      if !track.beatport_id.nil?
        $sheet.write_url($row_num, 5, "https://pro.beatport.com/track/x/#{track.beatport_id}", track_name)
      else
        $sheet.write($row_num, 5, track_name, $format_red)
      end
    end
  end
end

# book = Spreadsheet::Workbook.new
# $sheet = book.create_worksheet
book = WriteExcel.new("#{$export_dir}/#{$output_file_name}")
$sheet = book.add_worksheet
$format_red = book.add_format
$format_red.set_color("red")

#$out = File.new("#{$export_dir}/#{$output_file_name}", "#{$output_file_mode}")

#$sheet.insert_row(0, ["Release path", "Beatport", "Detail", "Label", "Release", "Track"])
$row_num = 0
$sheet.write(0,0, ["Release path", "Beatport", "Detail", "Label", "Release", "Track"])

if !$release_dir.nil?
  check_release("#{$lookup_dir}/#{$release_dir}")
else
  iterate_collection_releases($lookup_dir) do |release|
    check_release(release)
  end
end

#book.write("#{$export_dir}/#{$output_file_name}")
book.close