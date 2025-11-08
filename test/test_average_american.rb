# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require_relative '../average_american'

# Test helper methods
module TestHelpers
  FIXTURE_FILE = 'test/fixtures/census_parsed.json'
  BABY_NAMES_FIXTURE_FILE = 'test/fixtures/baby_names.json'

  def with_fixture_data
    # Temporarily copy fixture to expected location
    FileUtils.mkdir_p('data')
    FileUtils.cp(FIXTURE_FILE, DataLoader::PARSED_DATA_FILE)
    yield
  ensure
    # Clean up
    FileUtils.rm_f(DataLoader::PARSED_DATA_FILE)
  end

  def with_baby_names_fixture
    # Temporarily copy baby names fixture
    FileUtils.mkdir_p('data')
    FileUtils.cp(BABY_NAMES_FIXTURE_FILE, DataLoader::BABY_NAMES_FILE)
    yield
  ensure
    # Clean up
    FileUtils.rm_f(DataLoader::BABY_NAMES_FILE)
  end

  def without_census_data
    # Temporarily rename the file if it exists
    temp_file = nil
    if File.exist?(DataLoader::PARSED_DATA_FILE)
      temp_file = "#{DataLoader::PARSED_DATA_FILE}.tmp"
      File.rename(DataLoader::PARSED_DATA_FILE, temp_file)
    end
    yield
  ensure
    File.rename(temp_file, DataLoader::PARSED_DATA_FILE) if temp_file && File.exist?(temp_file)
  end
end

class TestStats < Minitest::Test
  def test_median_odd_number_of_values
    assert_equal 3, Stats.median([1, 2, 3, 4, 5])
  end

  def test_median_even_number_of_values
    assert_equal 3.5, Stats.median([1, 2, 3, 4, 5, 6])
  end

  def test_median_unsorted_values
    assert_equal 3, Stats.median([5, 1, 3, 2, 4])
  end

  def test_median_single_value
    assert_equal 42, Stats.median([42])
  end

  def test_median_empty_array
    assert_nil Stats.median([])
  end

  def test_mode_returns_most_common
    distribution = { 'Male' => 48.9, 'Female' => 51.1 }
    assert_equal 'Female', Stats.mode(distribution)
  end

  def test_mode_empty_distribution
    assert_nil Stats.mode({})
  end
end

class TestDataLoader < Minitest::Test
  include TestHelpers

  def test_load_demographics_success
    with_fixture_data do
      data = DataLoader.load_demographics
      assert_kind_of Hash, data
      assert data.key?('gender')
      assert data.key?('age')
    end
  end

  def test_load_demographics_has_gender_distribution
    with_fixture_data do
      data = DataLoader.load_demographics
      assert_kind_of Hash, data['gender']['distribution']
      assert data['gender']['distribution'].key?('Female')
      assert data['gender']['distribution'].key?('Male')
    end
  end

  def test_load_demographics_has_age_median
    with_fixture_data do
      data = DataLoader.load_demographics
      assert_kind_of Numeric, data['age']['median']
    end
  end

  def test_load_demographics_returns_latest_year_by_default
    with_fixture_data do
      data = DataLoader.load_demographics
      # Fixture has 2020, 2021, 2023 - should return 2023
      assert_equal 39.0, data['age']['median']
    end
  end

  def test_load_demographics_filters_by_year
    with_fixture_data do
      data = DataLoader.load_demographics(year: 2020)
      assert_equal 38.5, data['age']['median']
    end
  end

  def test_load_demographics_raises_for_invalid_year
    with_fixture_data do
      error = assert_raises(RuntimeError) do
        DataLoader.load_demographics(year: 2099)
      end
      assert_match(/No data available for year 2099/, error.message)
    end
  end

  def test_load_demographics_requires_fetch
    without_census_data do
      error = assert_raises(RuntimeError) do
        DataLoader.load_demographics
      end
      assert_match(/--fetch/, error.message)
      assert_match(/census.gov/, error.message)
    end
  end
end

class TestAveragePerson < Minitest::Test
  def setup
    @data = {
      'gender' => {
        'distribution' => { 'Female' => 51.1, 'Male' => 48.9 }
      },
      'age' => {
        'median' => 38.9
      }
    }

    @baby_names = {
      '1985' => {
        'baby_name' => {
          'most_popular' => { 'Male' => 'Michael', 'Female' => 'Jessica' }
        }
      }
    }
  end

  def test_gender_is_most_common
    person = AveragePerson.new(@data)
    assert_equal 'Female', person.gender
  end

  def test_age_is_median
    person = AveragePerson.new(@data)
    assert_equal 38.9, person.age
  end

  def test_to_s_formats_output_without_name
    person = AveragePerson.new(@data)
    output = person.to_s
    assert_match(/The Average American:/, output)
    assert_match(/Gender: Female/, output)
    assert_match(/Age: 38.9 years old/, output)
    refute_match(/Name:/, output)
  end

  def test_name_selected_based_on_birth_year_and_gender
    # Age 38.9 in 2024 = born in ~1985
    person = AveragePerson.new(@data, baby_names: @baby_names, current_year: 2024)
    assert_equal 'Jessica', person.name
  end

  def test_male_name_selected_for_male_gender
    male_data = {
      'gender' => { 'distribution' => { 'Male' => 55.0, 'Female' => 45.0 } },
      'age' => { 'median' => 38.9 }
    }
    person = AveragePerson.new(male_data, baby_names: @baby_names, current_year: 2024)
    assert_equal 'Michael', person.name
  end

  def test_to_s_includes_name_when_available
    person = AveragePerson.new(@data, baby_names: @baby_names, current_year: 2024)
    output = person.to_s
    assert_match(/Name: Jessica/, output)
    assert_match(/Gender: Female/, output)
    assert_match(/Age: 38.9 years old/, output)
  end

  def test_no_name_when_birth_year_not_in_data
    person = AveragePerson.new(@data, baby_names: @baby_names, current_year: 2050)
    assert_nil person.name
  end

  def test_no_name_when_baby_names_empty
    person = AveragePerson.new(@data, baby_names: {}, current_year: 2024)
    assert_nil person.name
  end
end
