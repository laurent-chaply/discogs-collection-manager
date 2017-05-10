require 'discogs'
require 'pry'
require 'logger'
require 'optparse'
require 'spreadsheet'
require 'discogs'
# require 'net-http-spy'
# Net::HTTP.http_logger_options = {:verbose => true}

APP_NAME = "YOUR DISCOGS APP NAME"
DEFAULT_FOLDER_ID = 1

# Options
$username = "YOUR DISCOGS USER NAME"
$user_token = "YOUR DISCOGS TOKEN ID"
$source_folder_id = 1
$target_folder_id = 626998
$skip_row = 952
$log_file_name = "add_to_folder.log"

$wrapper = Discogs::Wrapper.new(APP_NAME, user_token: $user_token)

$logger = Logger.new($log_file_name)

$logger.info("")
$logger.info("***********************************")
$logger.info("**** DISCOGS ADD TO FOLDER     ****")
$logger.info("***********************************")
$logger.info("")

book = Spreadsheet.open '../collection.xls'
sheet1 = book.worksheet 0
sheet1.each $skip_row do |row|
  if row[10] == "S"
    release_id = row[0].to_i
    instance_id = row[1].to_i
    $logger.info("Moving release #{release_id} instance #{instance_id} from folder #{$source_folder_id} to folder #{$target_folder_id}...")
    $wrapper.edit_release_in_user_folder($username, $source_folder_id, release_id, instance_id, {:folder_id => $target_folder_id})
    sleep 1.2
  end
end
