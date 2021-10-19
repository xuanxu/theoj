module Theoj
  class Orcid
    attr_reader :orcid, :error

    def initialize(orcid)
      @orcid = orcid.strip
      @error = nil
    end

    def valid?
      @error = nil
      return false unless check_structure
      return false unless check_length
      return false unless check_chars

      return false unless correct_checksum?

      true
    end

    def packed_orcid
      orcid.gsub('-', '')
    end

    private

    # Returns the last character of the string
    def checksum_char
      packed_orcid[-1]
    end

    def first_11
      packed_orcid.chop
    end

    def check_structure
      groups = orcid.split('-')
      if groups.size == 4
        return true
      else
        @error = "ORCID looks malformed"
        return false
      end
    end

    def check_length
      if packed_orcid.length == 16
        return true
      else
        @error = "ORCID looks to be the wrong length"
        return false
      end
    end

    def check_chars
      valid = true
      first_11.each_char do |c|
        if !numeric?(c)
          @error = "Invalid ORCID digit (#{c})"
          valid = false
        end
      end

      return valid
    end

    def correct_checksum?
      validate_against = checksum_char.to_i
      validate_against = 10 if (checksum_char == "X" || checksum_char == "x")

      if checksum == validate_against
        return true
      else
        @error = "Invalid ORCID"
        return false
      end
    end

    # https://support.orcid.org/knowledgebase/articles/116780-structure-of-the-orcid-identifier
    def checksum
      total = 0
      first_11.each_char do |c|
        total = (total + c.to_i) * 2
      end

      remainder = total % 11
      result = (12 - remainder) % 11
    end


    def numeric?(s)
      Float(s) != nil rescue false
    end

  end
end
