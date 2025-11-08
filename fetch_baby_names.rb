# frozen_string_literal: true

require 'csv'
require 'json'

# Script to parse NationalNames.csv and extract top baby names by year
class BabyNameParser
  def self.parse_csv(file_path = 'data/NationalNames.csv')
    data_by_year = Hash.new { |h, k| h[k] = { 'Male' => nil, 'Female' => nil } }

    CSV.foreach(file_path, headers: true) do |row|
      year = row['Year'].to_i
      name = row['Name']
      gender = row['Gender'] == 'M' ? 'Male' : 'Female'
      count = row['Count'].to_i

      # Since CSV is sorted by count (descending) within each year,
      # the first name we see for each year/gender is the most popular
      next if data_by_year[year][gender]

      data_by_year[year][gender] = { 'name' => name, 'count' => count }

      # Early exit if we have both genders for all years
      # (optimization for large files)
    end

    format_output(data_by_year)
  end

  def self.format_output(data_by_year)
    formatted = {}

    data_by_year.each do |year, genders|
      formatted[year.to_s] = {
        'baby_name' => {
          'source' => 'Social Security Administration (via Kaggle)',
          'source_url' => 'https://www.kaggle.com/datasets/kaggle/us-baby-names',
          'year' => year,
          'most_popular' => {
            'Male' => genders['Male']['name'],
            'Female' => genders['Female']['name']
          },
          'counts' => {
            'Male' => genders['Male']['count'],
            'Female' => genders['Female']['count']
          }
        }
      }
    end

    formatted
  end

  def self.save_parsed_data(data, output_file = 'data/baby_names.json')
    File.write(output_file, JSON.pretty_generate(data))
    puts "Saved baby name data to #{output_file}"
    puts "Years: #{data.keys.min} - #{data.keys.max}"
    puts "Total years: #{data.keys.size}"
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  puts 'Parsing NationalNames.csv...'
  data = BabyNameParser.parse_csv
  BabyNameParser.save_parsed_data(data)
  puts "\nSample data for 2014:"
  puts JSON.pretty_generate(data['2014'])
end
