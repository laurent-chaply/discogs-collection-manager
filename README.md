# discogs-collection-manager

**First project experiment with Ruby - Work in Progress

Scripts collection to gather data about my vinyl record collection 
and generate easy to use/share excel file compiling the data

- Gather records info from www.discogs.com
- Fetch recommended prices from Discogs marketplace
- Match the data with local digital files
> TODO the following are in separate "v1" scripts for now, to be integrated to the v2 script
- Add info from file names, MP3 tags etc ...
- Add extra information from iTunes library (ratings ...)
- ...

## Requirements
Access to Discogs API (user id, token ...) see
https://www.discogs.com/developers/

*Environment*

> TODO make it environemnt agnostic

Tested on OSX10.10+ (use spotlight *mdfind* to search for local files)

*Ruby*

Tested with ruby 2.4.0

Use [bundler](http://bundler.io/) to install required gems

`bundle install`

-Used gems-


pry<br>
stringex<br>
configuration<br>
yell<br>
persistent-cache<br>
writeexcel<br>
spreadsheet<br>
discogs-wrapper<br>
martinbtt-net-http-spy<br>
itunes_parser<br>

*Local digital files*

> TODO add sample directory tree

The script will try to match your digital files to match Discogs release
For now it requires a specific file naming pattern :
`Label name/[[Release date]] [[Catalog id]] Artists - Release Title/Track no - Artist - Title.mp3`
It will find the closest match in case of discrepencies (case, label naming, catalog id format ...)

## Configuration

(Uses https://github.com/ahoward/configuration format)

Copy sample [scripts/ruby/config/default.rb.sample](https://github.com/laurent-chaply/discogs-collection-manager/blob/v2/scripts/ruby/config/default.rb.sample) to *default.rb* and update the appropriate values

## Running main script

`ruby generate-master-collection.rb`

> TODO document script options

With configuration defaults it will generate a *master-collection.xls* file under `$HOME/Music/Records/Discogs`
Log files will be generated under `$HOME/.discogs-collection-manager/logs`

## First version scripts

The first version was independent scripts that generate CSV files for each type of info (records info, prices, iTunes info ...) that can be merged manually into a master xls, the integration of those in the main script is in progress. The old individual scripts are located in [scripts/ruby/v1](https://github.com/laurent-chaply/discogs-collection-manager/tree/v2/scripts/ruby/v1)
