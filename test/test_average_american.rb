# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../average_american'

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
  def test_load_demographics_success
    data = DataLoader.load_demographics
    assert_kind_of Hash, data
    assert data.key?('gender')
    assert data.key?('age')
  end

  def test_load_demographics_has_gender_distribution
    data = DataLoader.load_demographics
    assert_kind_of Hash, data['gender']['distribution']
    assert data['gender']['distribution'].key?('Female')
    assert data['gender']['distribution'].key?('Male')
  end

  def test_load_demographics_has_age_median
    data = DataLoader.load_demographics
    assert_kind_of Numeric, data['age']['median']
  end

  def test_load_static_demographics_file_not_found
    error = assert_raises(RuntimeError) do
      DataLoader.load_static_demographics('nonexistent.json')
    end
    assert_match(/not found/, error.message)
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
  end

  def test_gender_is_most_common
    person = AveragePerson.new(@data)
    assert_equal 'Female', person.gender
  end

  def test_age_is_median
    person = AveragePerson.new(@data)
    assert_equal 38.9, person.age
  end

  def test_to_s_formats_output
    person = AveragePerson.new(@data)
    output = person.to_s
    assert_match(/The Average American:/, output)
    assert_match(/Gender: Female/, output)
    assert_match(/Age: 38.9 years old/, output)
  end
end
