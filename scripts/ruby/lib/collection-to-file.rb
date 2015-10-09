module CollectionToFile
  class SearchInfo
    attr_reader :message, :query_info
    def initialize(label_info, query_info, level)
      @label_info = label_info
      @query_info = query_info
      @level = level
      @message = "[Level #{@level}] #{label_info.label} #{label_info.catno} #{label_info.title} #{search_query}"
    end
    def title?
      return @level == "T"
    end
    def label
      return @label_info.label
    end
    def search_query
      query = @query_info.join(" ")
      if !title?
        return "[#{query}]"
      else
        return query
      end
    end
  end

  class LabelInfo
    attr_reader :label, :catno, :title
    def initialize(label, catno, title)
      @label = label.to_s.downcase.gsub(/ ?\(\d+\)/,"").gsub(/[[:punct:] ]+/, " ")
      @catno = catno.to_s.downcase
      @title = title
      @catno_other = []
      @label_alt = []
      parsed_catno = @catno.gsub(/[[:punct:] ]+/, " ").split(" ")
      if parsed_catno.size > 1
        @label_alt << parsed_catno[0]
        parsed_catno[1..-1].each do |catno_part|
          resolve_compact_catno(catno_part, false)
        end
      elsif parsed_catno.size == 1
        resolve_compact_catno(parsed_catno[0])
      end
      if !@label_alt.empty?
        @label_alt << @label
        # label alternatives
        parsed_label = DiscogsUtils.normalize_label(@label)
        @label_alt << parsed_label.join(" ")
        parsed_label.each do |label_part|
          if accept_label_part(label_part)
            @label_alt << label_part
          end 
        end
        @label_alt.uniq!
      end
    end
    def accept_label_part(label_part)
      exclude_words = ["the"]
      return label_part.size >= 3 && !exclude_words.include?(label_part)
    end
    def resolve_compact_catno(catno, resolve_label = true)
      if catno.start_with?(@label)
        catno.slice!(@label)
        @label_alt << @label
        resolve_label = false
      end
      if result = catno.match(/(.*\D)?(\d+)(\D.*)?/)
        label = result.captures[0]
        catno_part1 = result.captures[1]
        catno_part2 = result.captures[2]
        if !label.nil?
          if resolve_label
            @label_alt << label
          else
            @catno_other << label
          end
        end
        @catno_other << catno_part1
        if !catno_part2.nil?
          @catno_other << catno_part2
        end
      else
        @catno_other << catno
      end
    end
    def search_infos(extra_search = true)
      search_infos = []
      level = 0
      search_infos << SearchInfo.new(self, [@catno], level)
      if !@label_alt.empty?
        level = 1
        @label_alt.each do |label_alt|
          search_infos << SearchInfo.new(self, [label_alt] + @catno_other, level)
          # workaround for spotligh strange single digit number handling
          add_fix_search(label_alt, search_infos, level)
          level += 1
        end
      end
      # Try with title
      if !@title.nil?
        if title = validate_title(@title)
          search_infos << SearchInfo.new(self, [title], "T")
        end
        # handles multiples " - " dirty
        # alt_titles = @title.split(" - ")
        # if alt_titles.size > 1
        #   alt_titles.each do |alt_title|
        #     if t = validate_title(alt_title)
        #       search_infos << SearchInfo.new(self, [alt_title], "T")
        #     end
        #   end
        # end
      end  
      return search_infos
    end
    def get_alt_titles
      alt_titles = @title.split(" - ")
    end
    def validate_title(title)
      if title.nil?
        return false
      end
      normalized_title = title.downcase.gsub(/[[:punct:] ]+/, " ").strip
      if res = normalized_title.match(/(.*)( e ?p|l ?p)$/)
        normalized_title = res.captures[0]
      end
      if normalized_title.match(/^(sampler|(the )?remix(e)?(s|d)?|revisited|untitled|(part|no|vol(ume)? )?\d+)$/) or
        normalized_title.size == 1
        logger.warn("Ignoring title #{normalized_title}")
        return false
      end
      return normalized_title
    end
    def get_alt_paddings(number)
      paddings = {}
      pad = String.new(number)
      removed = 0
      while pad.start_with?("0")
        pad.slice!("0")
        removed += 1
        paddings["-#{removed}"] = String.new(pad)  
      end
      paddings["+1"] = "0#{number}"
      paddings["+2"] = "00#{number}"
      return paddings
    end
    def add_fix_search(label_alt, search_infos, level)
      if result = @catno_other.last.match(/(.*\D+)?(\d+)$/)
        paddings = get_alt_paddings(result.captures[1])
        paddings.each do |k, padding|
          fix_catno = padding
          if !result.captures[0].nil?
            fix_catno = result.captures[0] + padding
          end
          query_info = [label_alt] + @catno_other[0..-2] << fix_catno
          search_infos << SearchInfo.new(self, query_info, "#{level}-pad#{k}")
        end
      end
    end
    def accept(search_info)
      self.search_infos(false).each do |si|
        logger.debug("comparing #{si.query_info} and #{search_info.query_info}")
        if DiscogsUtils.array_to_ascii(si.query_info, true) == DiscogsUtils.array_to_ascii(search_info.query_info, true)
          # Check lable when title
          if search_info.title? && DiscogsUtils.array_to_ascii(DiscogsUtils.normalize_label(search_info.label)) != DiscogsUtils.array_to_ascii(DiscogsUtils.normalize_label(@label))
            logger.warn("X Title match but label differs")
          else
            return true
          end
        end
      end
      return false
    end
  end
  
  class Matcher
    CACHE_NAME = "collection-to-file"
    
    def initialize(discogs_id, label, catno, title)
      @discogs_id = discogs_id
      @label = label
      @catno = catno
      @title = title
      @mismatch_detail = []
      load_blacklist
    end
    
    def load_blacklist
      @@blacklist = {}
      if @@blacklist.empty?
        blacklist_file = File.join(config.export_dir, config.collection.collection_to_file_blacklist)
        File.open(blacklist_file).readlines.each do |line|
          elements = line.strip.split(";")
          @@blacklist[elements[0].to_i] = elements[1]
        end
      end
    end
    
    def search
      result = CacheManager.get(CACHE_NAME, @discogs_id)
      if result.nil?
        result = search_uncached
        CacheManager.put(CACHE_NAME, @discogs_id, result)
      else
        logger.info("[CACHED] #{@label} #{@catno} #{result}")
      end
      
      return result == :match_not_found || result == :match_ambiguous ? false : result
    end
    
    def search_uncached
      logger.debug("")
      logger.debug("********* SEARCHING #{@label} #{@catno} **************")
      label_info = LabelInfo.new(@label, @catno, @title)
      end_result = :match_not_found
      label_info.search_infos.each do |search_info|
        result = do_search(@discogs_id, search_info)
        case result
        when :match_not_found
          #continue
        when :match_ambiguous
          end_result = result
        else
          return result
        end
      end
      case end_result
      when :match_ambiguous
        logger.warn("[AMBIGUOUS/NOT FOUND] #{@label} #{@catno}")
      else
        @mismatch_detail.each do |detail|
          logger.error(detail)
        end
        logger.error("[NOT FOUND] #{@label} #{@catno}")
      end
      return end_result
    end

    def do_search(release_id, search_info)
      logger.debug("search=#{search_info.search_query}")
      lookup_dir = "#{config.collection.dir_hq}/#{config.collection.base_dir}/"
      stdin, stdout = Open3.popen2e("mdfind", "-onlyin", lookup_dir, "-name", search_info.search_query)
      result = []
      stdout.readlines.each do |line|
        line.slice! lookup_dir
        if line.count("/") == 1
          result << line.strip
        end
      end
      if result.empty?
        return :match_not_found
      elsif result.size == 1
        return handle_found(release_id, search_info, result[0])
      else
        return handle_ambiguous(release_id, search_info, result)
      end
    end
    
    def validate(search_info, candidate)
      if regex_result = candidate.downcase.match(/([^\/]+)\/\[[^\]]+\] ?\[([^\]]+)\](( [^\-]+ \-)? (.*))?/)
        # pp "validating" + candidate
        return LabelInfo.new(regex_result.captures[0], regex_result.captures[1], regex_result.captures[4]).accept(search_info)
      end
      return false
    end

    # AMBIGUOUS CASE

    def handle_ambiguous(release_id, search_info, candidates)
      logger.warn("[AMBIGUITY]#{search_info.message}")
      solved_path = resolve_ambiguity(search_info, candidates)
      if solved_path.nil?
        return :match_ambiguous
      else
        return handle_found(release_id, search_info, solved_path, false)
      end
    end

    def resolve_ambiguity(search_info, candidates) 
      found = 0
      accepted_path = nil
      candidates.each do |candidate|
        if accepted_path != candidate && validate(search_info, candidate)
          logger.warn(" > #{candidate}")
          accepted_path = candidate
          found += 1
        else
          logger.warn(" X #{candidate}")
        end
      end
      if found == 1
        logger.warn(" ! Disambiguation OK")
        return accepted_path
      end
    end

    # FOUND CASE

    def handle_found(release_id, search_info, path, validate = true)
      if validate
        if !validate(search_info, path)
          @mismatch_detail << "[MISMATCH]#{search_info.message} > #{path}"
          return :match_not_found
        end
      end
      # pp $blacklist
      if path == @@blacklist[release_id]
        @mismatch_detail << "[BLACKLISTED]#{search_info.message} #{release_id} > #{path}"
        return :match_not_found
      end
      logger.info("[FOUND]#{search_info.message} > #{path}")
      return path
    end
  end
end