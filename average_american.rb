# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# Statistical calculation functions
module Stats
  def self.median(values)
    return nil if values.empty?

    sorted = values.sort
    size = sorted.size
    mid = size / 2

    if size.odd?
      sorted[mid]
    else
      (sorted[mid - 1] + sorted[mid]) / 2.0
    end
  end

  def self.mode(distribution)
    return nil if distribution.empty?

    distribution.max_by { |_key, value| value }&.first
  end
end

# Data loader for demographics
module DataLoader
  PARSED_DATA_FILE = 'data/census_parsed.json'
  BABY_NAMES_FILE = 'data/baby_names.json'

  def self.load_demographics(year: nil)
    unless File.exist?(PARSED_DATA_FILE)
      raise <<~ERROR
        No Census data found. Please download and parse Census data first by running:

            ruby average_american.rb --fetch

        This will download the latest data from census.gov and parse it for you.
      ERROR
    end

    all_data = JSON.parse(File.read(PARSED_DATA_FILE))
    return filter_by_year(all_data, year) if year

    # Return most recent year if no year specified
    latest_year = all_data.keys.map(&:to_i).max.to_s
    all_data[latest_year]
  end

  def self.load_baby_names
    return {} unless File.exist?(BABY_NAMES_FILE)

    JSON.parse(File.read(BABY_NAMES_FILE))
  end

  def self.filter_by_year(all_data, year)
    year_str = year.to_s
    raise "No data available for year #{year}" unless all_data.key?(year_str)

    all_data[year_str]
  end

  def self.save_parsed_data(data)
    File.write(PARSED_DATA_FILE, JSON.pretty_generate(data))
  end
end

# Historical Census data from Census Bureau and Wikipedia sources
module HistoricalData
  # Median ages from Census Decennial Census and Wikipedia
  # Source: https://en.wikipedia.org/wiki/Demographics_of_the_United_States
  # Decennial census years (1820-2010) and select recent years
  HISTORICAL_MEDIAN_AGES = {
    1820 => { total: 16.7, male: 16.6, female: 16.8 },
    1830 => { total: 17.2, male: 17.2, female: 17.3 },
    1840 => { total: 17.8, male: 17.9, female: 17.8 },
    1850 => { total: 18.9, male: 19.2, female: 18.6 },
    1860 => { total: 19.4, male: 19.8, female: 19.1 },
    1870 => { total: 20.2, male: 20.2, female: 20.1 },
    1880 => { total: 20.9, male: 21.2, female: 20.7 },
    1890 => { total: 22.0, male: 22.3, female: 21.6 },
    1900 => { total: 22.9, male: 23.3, female: 22.4 },
    1910 => { total: 24.1, male: 24.6, female: 23.5 },
    1920 => { total: 25.3, male: 25.8, female: 24.7 },
    1930 => { total: 26.5, male: 26.7, female: 25.2 },
    1940 => { total: 29.0, male: 29.1, female: 29.0 },
    1950 => { total: 30.2, male: 29.9, female: 30.5 },
    1960 => { total: 29.6, male: 28.7, female: 30.4 },
    1970 => { total: 28.1, male: 26.8, female: 29.8 },
    1980 => { total: 30.0, male: 28.8, female: 31.2 },
    1990 => { total: 32.9, male: 31.7, female: 34.1 },
    2000 => { total: 35.3, male: 34.0, female: 36.5 }
  }.freeze

  # Gender distribution percentages (approximate, based on historical trends)
  # Male percentage has remained around 49.2-49.5%, female around 50.5-50.8%
  GENDER_DISTRIBUTION = { male: 49.3, female: 50.7 }.freeze

  def self.get_historical_data(year)
    ages = HISTORICAL_MEDIAN_AGES[year]
    return nil unless ages

    {
      'gender' => {
        'source' => 'US Census Historical',
        'year' => year,
        'distribution' => {
          'Male' => GENDER_DISTRIBUTION[:male],
          'Female' => GENDER_DISTRIBUTION[:female]
        }
      },
      'age' => {
        'median' => ages[:total],
        'by_gender' => {
          'Male' => ages[:male],
          'Female' => ages[:female]
        }
      }
    }
  end
end

# Fetches data from Census.gov ACS API
module CensusFetcher
  ACS_API_BASE = 'https://api.census.gov/data'
  # ACS 1-year data is available for most years 2010-2024, except 2020 (suspended due to COVID-19)
  ACS_AVAILABLE_YEARS = (2010..2024).to_a - [2020]

  def self.fetch_acs_data
    puts 'Fetching data from Census sources...'
    data_by_year = {}

    # Add historical data from decennial census (1820-2000)
    historical_years = HistoricalData::HISTORICAL_MEDIAN_AGES.keys.sort
    historical_years.each do |year|
      puts "  Adding historical year #{year}..."
      historical_data = HistoricalData.get_historical_data(year)
      data_by_year[year.to_s] = historical_data if historical_data
    end

    # Fetch ACS data (2010-2024, excluding 2020)
    ACS_AVAILABLE_YEARS.each do |year|
      puts "  Fetching year #{year} from ACS API..."
      data_by_year[year.to_s] = fetch_year_data(year)
    end

    data_by_year
  end

  def self.fetch_year_data(year)
    age_data = fetch_age_data(year)
    gender_data = fetch_gender_data(year)

    {
      'gender' => gender_data,
      'age' => age_data
    }
  end

  def self.fetch_age_data(year)
    age_url = "#{ACS_API_BASE}/#{year}/acs/acs1?get=B01002_001E,B01002_002E,B01002_003E&for=us:1"
    age_response = Net::HTTP.get_response(URI(age_url))
    raise "Failed to fetch age data for #{year}: #{age_response.code}" unless age_response.code == '200'

    age_data = JSON.parse(age_response.body)
    {
      'median' => age_data[1][0].to_f,
      'by_gender' => {
        'Male' => age_data[1][1].to_f,
        'Female' => age_data[1][2].to_f
      }
    }
  end

  # rubocop:disable Metrics/AbcSize
  def self.fetch_gender_data(year)
    pop_url = "#{ACS_API_BASE}/#{year}/acs/acs1?get=B01001_001E,B01001_002E,B01001_026E&for=us:1"
    pop_response = Net::HTTP.get_response(URI(pop_url))
    raise "Failed to fetch population data for #{year}: #{pop_response.code}" unless pop_response.code == '200'

    pop_data = JSON.parse(pop_response.body)
    total_pop = pop_data[1][0].to_f
    male_pop = pop_data[1][1].to_f
    female_pop = pop_data[1][2].to_f

    {
      'source' => 'US Census ACS',
      'year' => year,
      'distribution' => {
        'Male' => (male_pop / total_pop * 100).round(1),
        'Female' => (female_pop / total_pop * 100).round(1)
      }
    }
  end
  # rubocop:enable Metrics/AbcSize
end

# Represents the average American based on demographic data
class AveragePerson
  attr_reader :gender, :age, :name

  def initialize(data, baby_names: {}, current_year: Time.now.year, gender: nil)
    @gender_specified = !gender.nil?
    @gender = gender || Stats.mode(data['gender']['distribution'])
    # Use gender-specific median age if gender is specified, otherwise use overall median
    @age = if @gender_specified && data.dig('age', 'by_gender', @gender)
             data['age']['by_gender'][@gender]
           else
             data['age']['median']
           end
    @current_year = current_year
    @name = determine_name(baby_names)
  end

  def to_s
    gender_title = if @gender_specified
                     case @gender
                     when 'Male' then ' Man'
                     when 'Female' then ' Woman'
                     else ''
                     end
                   else
                     ''
                   end
    output = "The Average American#{gender_title}:\n"
    output += "- Name: #{@name}\n" if @name
    output += "- Gender: #{@gender}\n"
    output += "- Age: #{@age.round(1)} years old"
    output
  end

  private

  def determine_name(baby_names)
    return nil if baby_names.empty? || @gender.nil? || @age.nil?

    birth_year = (@current_year - @age).round
    birth_year_data = baby_names[birth_year.to_s]

    return nil unless birth_year_data&.dig('baby_name', 'most_popular')

    birth_year_data['baby_name']['most_popular'][@gender]
  end
end

# Table formatter for displaying profiles
module TableFormatter
  def self.print_profiles_table(all_data, baby_names)
    years = all_data.keys.map(&:to_i).sort
    rows = build_table_rows(years, all_data, baby_names)
    print_table(rows)
  end

  def self.build_table_rows(years, all_data, baby_names)
    years.map do |year|
      data = all_data[year.to_s]
      build_row_for_year(year, data, baby_names)
    end
  end

  # rubocop:disable Metrics/AbcSize
  def self.build_row_for_year(year, data, baby_names)
    avg_american = AveragePerson.new(data, baby_names: baby_names, current_year: year)
    avg_man = AveragePerson.new(data, baby_names: baby_names, current_year: year, gender: 'Male')
    avg_woman = AveragePerson.new(data, baby_names: baby_names, current_year: year, gender: 'Female')

    {
      year: year,
      avg_name: avg_american.name || 'N/A',
      avg_gender: avg_american.gender,
      avg_age: avg_american.age.round(1),
      avg_birth_year: (year - avg_american.age).round,
      man_name: avg_man.name || 'N/A',
      man_age: avg_man.age.round(1),
      man_birth_year: (year - avg_man.age).round,
      woman_name: avg_woman.name || 'N/A',
      woman_age: avg_woman.age.round(1),
      woman_birth_year: (year - avg_woman.age).round
    }
  end
  # rubocop:enable Metrics/AbcSize

  def self.print_table(rows)
    print_header
    rows.each { |row| print_row(row) }
    puts
  end

  # rubocop:disable Metrics/AbcSize
  def self.print_header
    year_col = 'Year'.center(6)
    # Average American: Name(12) + space + Gender(8) + space + Age(8) + space + Birth(6) = 37
    avg_col = 'Average American'.center(37)
    # Average Man: Name(12) + space + Age(6) + space + Birth(6) = 26
    man_col = 'Average Man'.center(26)
    # Average Woman: Name(12) + space + Age(6) + space + Birth(6) = 26
    woman_col = 'Average Woman'.center(26)
    puts "\n#{year_col} | #{avg_col} | #{man_col} | #{woman_col}"

    name1 = 'Name'.center(12)
    gender = 'Gender'.center(8)
    age1 = 'Age'.center(8)
    birth1 = 'Birth'.center(6)
    name2 = 'Name'.center(12)
    age2 = 'Age'.center(6)
    birth2 = 'Birth'.center(6)
    name3 = 'Name'.center(12)
    age3 = 'Age'.center(6)
    birth3 = 'Birth'.center(6)
    subheader = "#{' ' * 6} | #{name1} #{gender} #{age1} #{birth1} | #{name2} #{age2} #{birth2} | "
    subheader += "#{name3} #{age3} #{birth3}"
    puts subheader
    puts '-' * 107
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def self.print_row(row)
    year = row[:year].to_s.center(6)
    avg_name = row[:avg_name].center(12)
    avg_gender = row[:avg_gender].center(8)
    avg_age = row[:avg_age].to_s.center(8)
    avg_birth = row[:avg_birth_year].to_s.center(6)
    man_name = row[:man_name].center(12)
    man_age = row[:man_age].to_s.center(6)
    man_birth = row[:man_birth_year].to_s.center(6)
    woman_name = row[:woman_name].center(12)
    woman_age = row[:woman_age].to_s.center(6)
    woman_birth = row[:woman_birth_year].to_s.center(6)
    output = "#{year} | #{avg_name} #{avg_gender} #{avg_age} #{avg_birth} | #{man_name} #{man_age} #{man_birth} | "
    output += "#{woman_name} #{woman_age} #{woman_birth}"
    puts output
  end
  # rubocop:enable Metrics/AbcSize
end

# Command-line interface
module CLI
  def self.parse_args(args)
    options = { year: nil, fetch: false, gender: nil }

    args.each do |arg|
      case arg
      when /^--year=(\d+)$/
        options[:year] = ::Regexp.last_match(1).to_i
      when /^--gender=(male|female)$/i
        options[:gender] = ::Regexp.last_match(1).capitalize
      when '--fetch'
        options[:fetch] = true
      when '--help', '-h'
        print_help
        exit 0
      end
    end

    options
  end

  def self.print_help
    puts <<~HELP
      Usage: ruby average_american.rb [OPTIONS]

      Options:
        --year=YYYY           Show average American for specific year (1820-2024, excl. 2020)
        --gender=male|female  Show average American of specific gender
        --fetch               Fetch Census data (historical + ACS API)
        --help, -h            Show this help message

      Examples:
        ruby average_american.rb                          # Show table of 3 profiles for all years
        ruby average_american.rb --year=2023              # Show 3 profiles for specific year
        ruby average_american.rb --gender=male            # Show average American man (latest year)
        ruby average_american.rb --year=2023 --gender=female  # Combine options
        ruby average_american.rb --fetch                  # Download Census data

      Default behavior shows a table across all years with 3 profiles:
        1. The Average American (gender from mode, age from overall median)
        2. The Average Man (fixed gender, age from male-specific median)
        3. The Average Woman (fixed gender, age from female-specific median)
    HELP
  end

  def self.fetch_and_parse
    parsed_data = CensusFetcher.fetch_acs_data
    puts "Fetched data for years: #{parsed_data.keys.sort.join(', ')}"

    puts 'Saving data...'
    DataLoader.save_parsed_data(parsed_data)
    puts 'Data saved successfully!'
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  begin
    options = CLI.parse_args(ARGV)

    if options[:fetch]
      CLI.fetch_and_parse
      exit 0
    end

    baby_names = DataLoader.load_baby_names

    if options[:year]
      # Show specified year
      data = DataLoader.load_demographics(year: options[:year])

      if options[:gender]
        # Show only the specified gender
        person = AveragePerson.new(data, baby_names: baby_names, current_year: options[:year], gender: options[:gender])
        puts person
      else
        # Show 3 profiles: Average American, Average Man, Average Woman
        # 1. Average American (gender from mode, age from overall median, name conditioned on gender)
        avg_american = AveragePerson.new(data, baby_names: baby_names, current_year: options[:year])
        puts avg_american
        puts "\n#{'-' * 50}\n\n"

        # 2. Average Man (gender fixed to Male, age from male median, name conditioned on Male)
        male_person = AveragePerson.new(data, baby_names: baby_names, current_year: options[:year], gender: 'Male')
        puts male_person
        puts "\n#{'-' * 50}\n\n"

        # 3. Average Woman (gender fixed to Female, age from female median, name conditioned on Female)
        female_person = AveragePerson.new(data, baby_names: baby_names, current_year: options[:year], gender: 'Female')
        puts female_person
      end
      puts "(Year: #{options[:year]})"
    else
      # Show 3 profiles for all years in a table by default
      unless File.exist?(DataLoader::PARSED_DATA_FILE)
        raise <<~ERROR
          No Census data found. Please download and parse Census data first by running:

              ruby average_american.rb --fetch

          This will download the latest data from census.gov and parse it for you.
        ERROR
      end

      all_data = JSON.parse(File.read(DataLoader::PARSED_DATA_FILE))

      if options[:gender]
        # Show only the specified gender for latest year
        latest_year = all_data.keys.map(&:to_i).max
        data = all_data[latest_year.to_s]
        person = AveragePerson.new(data, baby_names: baby_names, current_year: latest_year, gender: options[:gender])
        puts person
        puts "(Year: #{latest_year})"
      else
        # Show table of all years with 3 profiles each
        TableFormatter.print_profiles_table(all_data, baby_names)
      end
    end
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
