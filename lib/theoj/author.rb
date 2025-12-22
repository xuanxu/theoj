require "nameable"

module Theoj
  class Author
    attr_accessor :name
    attr_accessor :orcid
    attr_accessor :affiliation

    AUTHOR_FOOTNOTE_REGEX = /^[^\^]*/

    # Initialized with authors & affiliations block in the YAML header from an Open Journal paper
    # e.g. https://joss.readthedocs.io/en/latest/submitting.html#example-paper-and-bibliography
    def initialize(name, orcid, index, affiliations_hash)
      parse_name name
      @orcid = validate_orcid orcid
      @affiliation = build_affiliation_string(index, affiliations_hash)
    end

    def given_name
      @parsed_name.first
    end

    def middle_name
      @parsed_name.middle
    end

    def last_name
      name_parts = [@non_dropping_particle, @parsed_name.last, @parsed_name.suffix].map do |part|
        part.to_s.strip
      end.reject(&:empty?)

      fallback = @parsed_name.last || @literal_name

      name_parts.empty? ? fallback : name_parts.join(" ")
    end

    def citation_last_name
      @literal_name || last_name
    end

    def initials
      [@parsed_name.first, @parsed_name.middle].compact.map {|v| v[0] + "."} * ' '
    end

    def to_h
      {
        given_name: given_name,
        middle_name: middle_name,
        last_name: last_name,
        orcid: orcid,
        affiliation: affiliation
      }
    end

    private

    def parse_name(author_name)
      if author_name.is_a? Hash
        name_parts = normalize_name_parts(author_name)
        given_names = strip_footnotes(name_parts[:given_names])
        dropping_particle = strip_footnotes(name_parts[:dropping_particle])
        @non_dropping_particle = strip_footnotes(name_parts[:non_dropping_particle]) || dropping_particle
        display_dropping_particle = name_parts[:non_dropping_particle].nil? ? nil : dropping_particle
        surname = strip_footnotes(name_parts[:surname])
        suffix = strip_footnotes(name_parts[:suffix])
        @literal_name = strip_footnotes(name_parts[:literal])

        surname_with_particle = [@non_dropping_particle, surname].compact.reject(&:empty?).join(" ")
        name_hash = {
          first: given_names,
          middle: dropping_particle,
          last: surname_with_particle,
          suffix: suffix
        }

        @parsed_name = Nameable::Latin.new(name_hash)
        @name = @literal_name || build_display_name(given_names, display_dropping_particle, @non_dropping_particle, surname, suffix)
      else
        parsed_name = Nameable::Latin.new.parse(strip_footnotes(author_name))
        @parsed_name = parsed_name
        @name = parsed_name.to_s
      end
    end

    def normalize_name_parts(author_hash)
      {
        literal: fetch_name_field(author_hash, %w[literal]),
        given_names: fetch_name_field(author_hash, ["given-names", "given", "first", "firstname"]),
        dropping_particle: fetch_name_field(author_hash, ["dropping-particle"]),
        non_dropping_particle: fetch_name_field(author_hash, ["non-dropping-particle"]),
        surname: fetch_name_field(author_hash, ["surname", "family"]),
        suffix: fetch_name_field(author_hash, ["suffix"])
      }
    end

    def fetch_name_field(name_hash, keys)
      keys.map do |key|
        name_hash[key] || name_hash[key.to_sym]
      end.compact.first
    end

    def build_display_name(given_names, dropping_particle, non_dropping_particle, surname, suffix)
      [given_names, dropping_particle, non_dropping_particle, surname, suffix].map do |part|
        part.to_s.strip
      end.reject(&:empty?).join(" ")
    end

    # Input: Arfon Smith^[Corresponding author: arfon@example.com]
    # Output: Arfon Smith
    def strip_footnotes(author_name)
      author_name.to_s[AUTHOR_FOOTNOTE_REGEX]
    end

    def validate_orcid(author_orcid)
      return nil if author_orcid.to_s.strip.empty?

      validator = Theoj::Orcid.new(author_orcid)
      if validator.valid?
        return author_orcid.strip
      else
        raise Theoj::Error, "Problem with ORCID (#{author_orcid}) for #{self.name}. #{validator.error}"
      end
    end

    # Takes the author affiliation index and a hash of all affiliations and
    # associates them. Then builds the author affiliation string
    def build_affiliation_string(index, affiliations_hash)
      return nil if index.nil? # Some authors don't have an affiliation

      # If multiple affiliations, parse each one and build the affiliation string
      author_affiliations = []

      # Turn YAML keys into strings so that mixed integer and string affiliations work
      affiliations_hash.transform_keys!(&:to_s)

      affiliations = index.to_s.split(',').map(&:strip)

      # Raise if we can't parse the string, might be because of this bug :-(
      # https://bugs.ruby-lang.org/issues/12451
      affiliations.each do |a|
        raise Theoj::Error, "Problem with affiliations for #{self.name}, perhaps the " +
              "affiliations index need quoting?" unless affiliations_hash.has_key?(a)

        author_affiliations << affiliations_hash[a].strip
      end

      author_affiliations.join(', ')
    end

  end
end
