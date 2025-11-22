# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'roo'

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

# Fetches data from Census.gov
module CensusFetcher
  CENSUS_URL = 'https://www2.census.gov/programs-surveys/popest/tables/2020-2024/national/asrh/nc-est2024-agesex.xlsx'
  CACHE_DIR = 'data/cache'

  def self.download_file(url = CENSUS_URL)
    FileUtils.mkdir_p(CACHE_DIR)
    file_path = File.join(CACHE_DIR, 'census_age_sex.xlsx')

    return file_path if File.exist?(file_path)

    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    raise "Failed to download file: #{response.code}" unless response.code == '200'

    File.binwrite(file_path, response.body)
    file_path
  end
end

# Parses Census Excel file to extract demographic data
module CensusParser
  TOTAL_ROW = 6
  MEDIAN_AGE_ROW = 40
  YEAR_ROW = 4

  def self.parse_excel(file_path)
    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    data_by_year = {}
    years = extract_years(sheet)

    years.each do |year, col_index|
      gender_data = extract_gender_data(sheet, col_index)
      age_data = extract_age_data(sheet, col_index)

      data_by_year[year] = {
        'gender' => {
          'source' => 'US Census',
          'year' => year,
          'distribution' => gender_data
        },
        'age' => age_data
      }
    end

    data_by_year
  end

  def self.extract_years(sheet)
    # Row 4 contains years - find columns where years appear
    years = {}
    (1..sheet.last_column).each do |col|
      cell_value = sheet.cell(YEAR_ROW, col).to_s.strip
      # Look for 4-digit years
      years[cell_value.to_i] = col if cell_value =~ /^202[0-4]$/
    end
    years
  end

  def self.extract_gender_data(sheet, both_sexes_col)
    # For this Census format:
    # both_sexes_col = Both Sexes column
    # both_sexes_col + 1 = Male column
    # both_sexes_col + 2 = Female column
    # Row 6 = Total population
    male_col = both_sexes_col + 1
    female_col = both_sexes_col + 2

    male_pop = parse_number(sheet.cell(TOTAL_ROW, male_col))
    female_pop = parse_number(sheet.cell(TOTAL_ROW, female_col))

    calculate_gender_percentages('Male' => male_pop, 'Female' => female_pop)
  end

  def self.calculate_gender_percentages(gender_data)
    total = gender_data.values.sum
    return {} if total.zero?

    {
      'Male' => (gender_data['Male'] / total * 100).round(1),
      'Female' => (gender_data['Female'] / total * 100).round(1)
    }
  end

  def self.extract_age_data(sheet, both_sexes_col)
    # Row 40 contains median ages
    # both_sexes_col is the "Both Sexes" column for this year
    # both_sexes_col + 1 = Male column
    # both_sexes_col + 2 = Female column
    median_age = parse_number(sheet.cell(MEDIAN_AGE_ROW, both_sexes_col))
    median_age_male = parse_number(sheet.cell(MEDIAN_AGE_ROW, both_sexes_col + 1))
    median_age_female = parse_number(sheet.cell(MEDIAN_AGE_ROW, both_sexes_col + 2))
    {
      'median' => median_age,
      'by_gender' => {
        'Male' => median_age_male,
        'Female' => median_age_female
      }
    }
  end

  def self.parse_number(cell_value)
    cell_value.to_s.gsub(/[,\s]/, '').to_f
  end
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
        --year=YYYY           Show average American for specific year (2020-2024)
        --gender=male|female  Show average American of specific gender
        --fetch               Download and parse latest Census data
        --help, -h            Show this help message

      Examples:
        ruby average_american.rb                          # Show 3 profiles for latest year
        ruby average_american.rb --year=2023              # Show 3 profiles for specific year
        ruby average_american.rb --gender=male            # Show average American man (latest year)
        ruby average_american.rb --year=2023 --gender=female  # Combine options
        ruby average_american.rb --fetch                  # Download Census data

      Default behavior outputs 3 profiles:
        1. The Average American (gender from mode, age from overall median)
        2. The Average Man (fixed gender, age from male-specific median)
        3. The Average Woman (fixed gender, age from female-specific median)
    HELP
  end

  def self.fetch_and_parse
    puts 'Downloading Census data...'
    file_path = CensusFetcher.download_file
    puts "Downloaded to #{file_path}"

    puts 'Parsing Excel file...'
    parsed_data = CensusParser.parse_excel(file_path)
    puts "Parsed data for years: #{parsed_data.keys.sort.join(', ')}"

    puts 'Saving parsed data...'
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
      # Show 3 profiles for most recent year by default
      unless File.exist?(DataLoader::PARSED_DATA_FILE)
        raise <<~ERROR
          No Census data found. Please download and parse Census data first by running:

              ruby average_american.rb --fetch

          This will download the latest data from census.gov and parse it for you.
        ERROR
      end

      all_data = JSON.parse(File.read(DataLoader::PARSED_DATA_FILE))
      latest_year = all_data.keys.map(&:to_i).max
      data = all_data[latest_year.to_s]

      if options[:gender]
        # Show only the specified gender
        person = AveragePerson.new(data, baby_names: baby_names, current_year: latest_year, gender: options[:gender])
        puts person
      else
        # Show 3 profiles: Average American, Average Man, Average Woman
        # 1. Average American (gender from mode, age from overall median, name conditioned on gender)
        avg_american = AveragePerson.new(data, baby_names: baby_names, current_year: latest_year)
        puts avg_american
        puts "\n#{'-' * 50}\n\n"

        # 2. Average Man (gender fixed to Male, age from male median, name conditioned on Male)
        male_person = AveragePerson.new(data, baby_names: baby_names, current_year: latest_year, gender: 'Male')
        puts male_person
        puts "\n#{'-' * 50}\n\n"

        # 3. Average Woman (gender fixed to Female, age from female median, name conditioned on Female)
        female_person = AveragePerson.new(data, baby_names: baby_names, current_year: latest_year, gender: 'Female')
        puts female_person
      end
      puts "(Year: #{latest_year})"
    end
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
