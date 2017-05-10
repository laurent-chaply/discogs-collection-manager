require_relative "lib/common"
$max_page = 100
parse_options do |opts|
  opts.on("-p", "--to-page P", Integer) do |p|
    $max_page = p
  end
end
init

require_relative "lib/excel"
require_relative "lib/collection-to-file"

class ReleaseInfo
  attr_reader :id, :instance_id, :label, :catno, :artists, :title, :year, :local_path, :tracks, :prices
  def initialize(release, instance_id)
    @id = release.id
    @instance_id = instance_id
    @label = release.labels[0].name
    @catno = release.labels[0].catno
    @artists = DiscogsUtils.artists_to_str(release.artists)
    @title = release.title
    @year = release.year
    @local_path = nil
    @tracks = {}
    @prices = {}
  end
  def update_local_path(path)
    @local_path = path
  end
  def add_prices(price_info)
    DiscogsUtils::ITEM_CONDITIONS.each do |condition, condition_long|
      @prices[condition] = price_info[condition_long].nil? ? nil : price_info[condition_long].value
    end
  end
  def add_tracks(tracklist)
    tracklist.each do |track|
      add_track(track.position, TrackInfo.new(self, track))
    end
  end
  def add_track(pos, track)
    @tracks[pos] = track
  end
end

class TrackInfo
  attr_reader :artists, :title
  def initialize(release, track)
    @release = release
    artists = track.artists
    if artists.nil?
      @artists = release.artists
    else
      @artists = DiscogsUtils.artists_to_str(artists)
    end
    @title = track.title
    @release.add_track(track.position, self)
  end
end

def get_release_info(collection_release)
  release, cached = DiscogsWrapper.call("get_release", collection_release.id)
  logger.info("fetched release #{collection_release.id} details (#{cached})")
  release_info = ReleaseInfo.new(release, collection_release.instance_id)
  
  # tracks
  release_info.add_tracks(release.tracklist)
  
  # price
  price_info, cached = DiscogsWrapper.call("get_price_suggestions", release.id)
  logger.info("fetched release #{collection_release.id} price (#{cached})")
  release_info.add_prices(price_info)
  
  if release_local_path = CollectionToFile::Matcher.new(release_info.id, release_info.label, release_info.catno, release_info.title).search
    release_info.update_local_path(release_local_path)
  end
  if !release_local_path
    #TODO generate dummy release / use it as folder
  end
  #TODO collect tags sell, digital online > base dir = HQ
  
  return release_info
end

#TODO retrieve iTunes rating from cache, 
#TODO check beatport id for online status > base_dir = SQ Copy

def write_release_info(book, release_info)
  book.add_row([release_info.id, release_info.instance_id, release_info.local_path, release_info.label, release_info.catno, release_info.artists, release_info.title, release_info.year])
  # prices
  price_row = [release_info.prices[config.discogs.ref_condition]]
  price_row +=  release_info.prices.values
  book.append_to_row(price_row, 0, book.format_price, true)
  release_info.tracks.each do |pos, track_info|
    book.add_detail_row([pos, track_info.artists, track_info.title], 3)
  end
end

output = "master-collectiion.xls"
book = Excel::Workbook.new(output)
header = ["Discogs Id", "Instance Id", "Path", "Label", "Catalog #", "Artists", "Title", "Year"]
# Price
header << "#{config.discogs.ref_condition} >"
DiscogsUtils::ITEM_CONDITIONS.keys.each do |condition|
  header << condition
end
book.add_header(header)

page = 1
pages = page
while page <= pages && page <= $max_page
  collection, cached = DiscogsWrapper.call("get_user_folder_releases", config.discogs.user_name, config.discogs.default_folder_id, :page => page, :per_page => config.discogs.items_per_page)
  pages = collection.pagination.pages
  logger.info("")
  logger.info("* PAGE #{page} of #{pages} (#{cached})")
  logger.info("")
  collection.releases.select { |release| DiscogsUtils.is_vynil?(release.basic_information.formats) }.each do |release|
    release_info = get_release_info(release)
    write_release_info(book, release_info)
    #TODO write it on excel 2 sheets release + detail
  end
  page += 1
end

book.save
