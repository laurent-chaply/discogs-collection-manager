module DiscogsUtils
  FORMAT_VINYL = "Vinyl"
  ITEM_CONDITIONS = {
    "P" => "Poor (P)",
    "F" => "Fair (F)",
    "G" => "Good (G)",
    "G+" => "Good Plus (G+)",
    "VG" => "Very Good (VG)",
    "VG+" => "Very Good Plus (VG+)", 
    "NM" => "Near Mint (NM or M-)", 
    "M" => "Mint (M)"
  }
  
  def self.artists_to_str(artists)
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
  
  def self.is_vynil?(formats)
    return !formats.index { |format| format.name == FORMAT_VINYL }.nil?
  end
  
  def self.normalize_label(label)
    excluded_words = ["record","records","recording","recordings","music","audio","schallplatten"]
    return label.gsub(/[[:punct:] ]+/, " ").split.delete_if{ |x| excluded_words.include?(x) }
  end
  
  def self.array_to_ascii(string_array, downcase = false)
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
  
end