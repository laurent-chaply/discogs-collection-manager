require 'discogs'
require 'pry'
require 'logger'
require 'optparse'
require 'persistent-cache'
require 'spreadsheet'

# Generic constants
DEFAULT_WORK_DIR = "#{Dir.home}/.discogs-collection-manager"
DEFAULT_CACHE_DIR = "#{DEFAULT_WORK_DIR}/cache"
DEFAULT_LOG_DIR = "#{DEFAULT_WORK_DIR}/log"

# Discogs specific constants
ITEM_CONDITIONS = {"VG" => "Very Good (VG)", "VG+" => "Very Good Plus (VG+)", "NM" => "Near Mint (NM or M-)", "M" => "Mint (M)"}
FORMAT_VINYL = "Vinyl"
DEFAULT_FOLDER_ID = 0
UNCATEGORIZED_FOLDER_ID = 1

# Caching constants
CACHE_LIST = :collection, :price

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

# Logging functions

def initialize_log
  log_file = "#{DEFAULT_LOG_DIR}/#{$log_file_name}"
  if $reset_log && File.exists?(log_file)
    File.delete(log_file)
  end
  $logger = Logger.new(log_file)
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