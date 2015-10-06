require "discogs"
require "pry"
require "logger"
require "optparse"
require "persistent-cache"
require "spreadsheet"
require "open3"
require "stringex_lite"
require "taglib"
require "fileutils"

# Generic constants
DEFAULT_WORK_DIR = "#{Dir.home}/.discogs-collection-manager"
DEFAULT_CACHE_DIR = "#{DEFAULT_WORK_DIR}/cache"
DEFAULT_LOG_DIR = "#{DEFAULT_WORK_DIR}/log"

# Discogs specific constants
ITEM_CONDITIONS = {"VG" => "Very Good (VG)", "VG+" => "Very Good Plus (VG+)", "NM" => "Near Mint (NM or M-)", "M" => "Mint (M)"}
FORMAT_VINYL = "Vinyl"
DEFAULT_FOLDER_ID = 0
UNCATEGORIZED_FOLDER_ID = 1

# Local collection constants and variables
DEFAULT_COLLECTION_DIR_SQ = "#{Dir.home}/Music/00 - Main"
DEFAULT_COLLECTION_DIR_HQ = "/Volumes/Media/Music/ZZ - HQ Archive"
DEFAULT_COLLECTION_BASE_DIRECTORY = "Electronic/00 - By Label"

$collection_dir_sq = DEFAULT_COLLECTION_DIR_SQ
$collection_dir_hq = DEFAULT_COLLECTION_DIR_HQ
$collection_base_dir = DEFAULT_COLLECTION_BASE_DIRECTORY

# Caching constants
CACHE_LIST = :collection, :price, :folder_to_collection, :release

# Logging parameters
$reset_log = true
$log_file_name = $PROGRAM_NAME.sub("rb", "log")
$script_banner_title = "DISCOGS COLLECTION MANAGER"

# Discogs wrapper initialisation parameters
$app_name = "YOUR DISCOGS APP NAME"
$username = "YOUR DISCOGS USER NAME"
$user_token = "YOUR DISCOGS TOKEN ID"
$default_folder_id = 0

# Paging parameters
$start_page = 1
$items = 50

# Caching parameters
$do_cache = true
$flush_cache = []
$cache = {}

# CSV/XLS export parameters
$csv_separator = ";"
$float_separator = ","
$export_dir = "#{Dir.home}/Music/Records/Discogs"
$csv_yes = 1
$csv_no = 0
$csv_no_value = "-"

# spreadsheet parameters
$skip_row = 1

# Logging functions

def initialize_log
  log_file = "#{DEFAULT_LOG_DIR}/#{$log_file_name}"
  if $reset_log && File.exists?(log_file)
    File.delete(log_file)
  end
  $logger = Logger.new(log_file)
  $logger.level = Logger::INFO
end

def script_banner
  $logger.info ""
  $logger.info "***********************************"
  $logger.info "**** " + $script_banner_title
  $logger.info "***********************************"
  $logger.info ""
end

# Caching functions

def initialize_cache
  if $do_cache
    $logger.info(" > Caching enabled")
    CACHE_LIST.each do |name|
      cache_file = "#{DEFAULT_CACHE_DIR}/#{name}.cache"
      if $flush_cache.include?(name) && File.exists?(cache_file)
        $logger.warn(" > Flushing cache #{name}")
        File.delete(cache_file)
      end
      $cache[name] = Persistent::Cache.new(cache_file, nil)
    end
  else
    $logger.warn(" > Caching disabled")
  end
end

def initialize_discogs_wrapper
  $wrapper = Discogs::Wrapper.new($app_name, user_token: $user_token)
end

# Disocgs data formatting functions

def collection_release_basics(release)
  return [release.id, release.basic_information.labels[0].name, release.basic_information.labels[0].catno, artists_to_str(release), release.basic_information.title]
end

def collection_release_to_str(release, separator = " - ")
  return collection_release_basics(release).join(separator)
end

def normalize_label(label)
  excluded_words = ["record","records","recording","recordings","music","audio","schallplatten"]
  return label.gsub(/[[:punct:] ]+/, " ").split.delete_if{ |x| excluded_words.include?(x) }
end


def artists_to_str2(artists)
  artists_array = []
  join = ""
  artists.each do |artist|
    name = join + artist.name
    join = artist.join
    if join != ""
      join = " " + join + " "
    else
      join = ", "
    end
    artists_array.push(name)
  end
  return artists_array.join()
end

def artists_to_str(release)
  artists = release.basic_information.artists
  artists_array = []
  join = ""
  artists.each do |artist|
    name = join + artist.name
    join = artist.join
    if join != ""
      join = " " + join + " "
    else
      join = ", "
    end
    artists_array.push(name)
  end
  return artists_array.join()
end

def is_vinyl?(release)
  formats = release.basic_information.formats
  formats.each do |format|
    if format.name == FORMAT_VINYL
      return true
    end
  end
  return false
end

def array_to_ascii(string_array, downcase = false)
  ascii = []
  string_array.each do |s|
    if downcase
      ascii << s.to_ascii.downcase
    else
      ascii << s.to_ascii
    end  
  end
  return ascii
end

def force_str(value, name)
  str = value
  if value.is_a?(Float)
    $logger.warn("FORCING STRING FOR #{name} #{value}")
    if value.to_i == value
      return value.to_i.to_s
    else
      return value.to_s
    end
  else
    return value
  end 
end

def iterate_subdir(dir, &block)
  Dir.entries(dir).each do |filename|
    if ![".",".."].include?(filename)
      file = File.join(dir,filename)
      if File.directory?(file)
        block.call(file)
      end
    end
  end
end

def iterate_files(dir, regex, &block)
  if File.exists?(dir)
    Dir.entries(dir).select { |f| f =~ regex }.each do |filename|
      file = File.join(dir, filename)
      block.call(file)
    end
  else
    $logger.warn ("[FILE NOT FOUND] #{dir}")
  end 
end

def iterate_collection_releases(dir, &block)
  iterate_subdir(dir) do |label|
    iterate_subdir(label) do |release|
      block.call(release)
    end
  end
end

def iterate_collection_tracks(dir, regex, &block)
  iterate_collection_releases(dir) do |release| 
    iterate_files(release, regex) do |track|
      block.call(track)
    end
  end
end

def get_cached_release(id)
  cached = false
  if $do_cache
    release = $cache[:release][id]
  end
  if release.nil?
    sleep 1.2
    release = $wrapper.get_release(id)
    if $do_cache
      $cache[:release][id] = release
    end
  else
    cached = true
  end
  return release, cached
end
