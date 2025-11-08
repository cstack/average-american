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

  def self.load_demographics(year: nil)
    # Try to load from parsed census data first
    if File.exist?(PARSED_DATA_FILE)
      all_data = JSON.parse(File.read(PARSED_DATA_FILE))
      return filter_by_year(all_data, year) if year

      # Return most recent year if no year specified
      latest_year = all_data.keys.map(&:to_i).max.to_s
      return all_data[latest_year]
    end

    # Fall back to static data file
    load_static_demographics
  end

  def self.load_static_demographics(file_path = 'data/demographics.json')
    JSON.parse(File.read(file_path))
  rescue Errno::ENOENT
    raise "Demographics file not found: #{file_path}"
  rescue JSON::ParserError
    raise "Invalid JSON in demographics file: #{file_path}"
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
    median_age = parse_number(sheet.cell(MEDIAN_AGE_ROW, both_sexes_col))
    { 'median' => median_age }
  end

  def self.parse_number(cell_value)
    cell_value.to_s.gsub(/[,\s]/, '').to_f
  end
end

# Represents the average American based on demographic data
class AveragePerson
  attr_reader :gender, :age

  def initialize(data)
    @gender = Stats.mode(data['gender']['distribution'])
    @age = data['age']['median']
  end

  def to_s
    "The Average American:\n- Gender: #{@gender}\n- Age: #{@age.round(1)} years old"
  end
end

# Command-line interface
module CLI
  def self.parse_args(args)
    options = { year: nil, fetch: false }

    args.each do |arg|
      case arg
      when /^--year=(\d+)$/
        options[:year] = ::Regexp.last_match(1).to_i
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
        --year=YYYY    Show average American for specific year (2020-2024)
        --fetch        Download and parse latest Census data
        --help, -h     Show this help message

      Examples:
        ruby average_american.rb
        ruby average_american.rb --year=2023
        ruby average_american.rb --fetch
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

    data = DataLoader.load_demographics(year: options[:year])
    person = AveragePerson.new(data)
    puts person
    puts "(Year: #{options[:year] || 'latest'})" if options[:year] || File.exist?(DataLoader::PARSED_DATA_FILE)
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
