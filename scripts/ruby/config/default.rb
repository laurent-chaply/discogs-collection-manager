require "configuration"

Configuration.for("default") {
  app_name "DISCOGS COLLECTION MANAGER"
  default_work_dir "#{Dir.home}/.discogs-collection-manager"
  export_dir "#{Dir.home}/Music/Records/Discogs"
  log {
    reset true
  }
  discogs {
    app_name "YOUR DISCOGS APP NAME"
    user_name "YOUR DISCOGS USER NAME"
    user_token "YOUR DISCOGS TOKEN ID"
    wait_time 1.5
    default_folder_id 0
    items_per_page 50
    ref_condition "VG"
  }
  xls {
    default_font "Calibri"
    default_font_size 12
  }
  collection {
    dir_hq "/Volumes/Media/Music/ZZ - HQ Archive"
    dir_sq "#{Dir.home}/Music/00 - Main"
    base_dir "Electronic/00 - By Label"
    collection_to_file_blacklist "collection-to-file-blacklist.csv"
  }
}
