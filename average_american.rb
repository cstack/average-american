# frozen_string_literal: true

require 'json'

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
  def self.load_demographics(file_path = 'data/demographics.json')
    JSON.parse(File.read(file_path))
  rescue Errno::ENOENT
    raise "Demographics file not found: #{file_path}"
  rescue JSON::ParserError
    raise "Invalid JSON in demographics file: #{file_path}"
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

# Main execution
if __FILE__ == $PROGRAM_NAME
  begin
    data = DataLoader.load_demographics
    person = AveragePerson.new(data)
    puts person
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
