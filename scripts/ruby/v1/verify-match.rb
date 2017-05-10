require_relative "common/common"

def parse_specific_options(opts)
end

require_relative "common/init"

File.open("#{$export_dir}/diff.csv").each do |line|
  discogs_id, path = line.split(";")
  release = $wrapper.get_release(discogs_id)
  $logger.info "#{path.strip} = #{release.labels[0].name} - #{release.labels[0].catno} - #{artists_to_str2(release.artists)} - #{release.title}"
  sleep 1.2
end