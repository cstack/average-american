# Average American

A Ruby command-line tool that constructs a profile of the "average American" based on demographic data from the U.S. Census Bureau. Inspired by [John Green's video "I Was Wrong about the Average American"](https://www.youtube.com/watch?v=tEDXVGHW4Gg).

## Features

- Fetches and parses real demographic data from the U.S. Census Bureau
- Calculates median age and gender distribution (mode)
- Determines most popular baby name based on gender and implied birth year
- Shows profiles for both male and female for the most recent year by default
- Supports filtering by specific year (2020-2024)
- Supports filtering by gender (male or female)
- Caches data locally for offline use
- Fully tested with minitest
- Linted with rubocop

## Installation

1. Clone this repository
2. Install dependencies:

```bash
bundle install
```

## Usage

### First Time Setup: Fetch Census Data

**Required before first use:** Download and parse the latest Census data:

```bash
ruby average_american.rb --fetch
```

This will:
- Download the Census Excel file from census.gov (one-time download, cached locally)
- Parse demographic data for years 2020-2024
- Save the parsed data to `data/census_parsed.json`

If you try to run the script without fetching first, you'll see a helpful error message with instructions.

### (Optional) Parse Baby Name Data

If you have the `data/NationalNames.csv` file (from [Kaggle](https://www.kaggle.com/datasets/kaggle/us-baby-names)), parse it to enable baby name features:

```bash
ruby fetch_baby_names.rb
```

This will create `data/baby_names.json` with the most popular baby names by year and gender.

### Show Average American Profiles

After fetching data, show profiles for both genders for the most recent year:

```bash
ruby average_american.rb
```

Output:
```
The Average American Man:
- Name: Michael
- Gender: Male
- Age: 39.1 years old
(Year: 2024)

--------------------------------------------------

The Average American Woman:
- Name: Jessica
- Gender: Female
- Age: 39.1 years old
(Year: 2024)
```

### Show a Specific Year

Show both genders for a specific year:

```bash
ruby average_american.rb --year=2020
```

Output:
```
The Average American Man:
- Name: Michael
- Gender: Male
- Age: 38.5 years old
(Year: 2020)

--------------------------------------------------

The Average American Woman:
- Name: Jennifer
- Gender: Female
- Age: 38.5 years old
(Year: 2020)
```

### Filter by Gender

Show only a specific gender for the most recent year:

```bash
ruby average_american.rb --gender=male
```

Output:
```
The Average American Man:
- Name: Michael
- Gender: Male
- Age: 39.1 years old
(Year: 2024)
```

You can also combine gender with year to show only that gender for a specific year:

```bash
ruby average_american.rb --year=2023 --gender=female
```

Output:
```
The Average American Woman:
- Name: Jennifer
- Gender: Female
- Age: 39.0 years old
(Year: 2023)
```

### Help

Show help message:

```bash
ruby average_american.rb --help
```

## Data Sources

- **Census Bureau**: Age and gender data from [Annual Estimates of the Resident Population](https://www2.census.gov/programs-surveys/popest/tables/2020-2024/national/asrh/nc-est2024-agesex.xlsx)
- **Baby Names**: Social Security Administration data via [Kaggle US Baby Names dataset](https://www.kaggle.com/datasets/kaggle/us-baby-names) (1880-2014)

## Project Structure

```
average-american/
├── average_american.rb          # Main script with all modules
├── fetch_baby_names.rb          # Script to parse baby names CSV
├── test/
│   ├── test_average_american.rb # Test suite
│   └── fixtures/
│       ├── census_parsed.json   # Test fixture data
│       └── baby_names.json      # Baby names fixture data
├── data/
│   ├── NationalNames.csv        # Raw baby names data (from Kaggle)
│   ├── census_parsed.json       # Parsed Census data (created by --fetch)
│   ├── baby_names.json          # Parsed baby names (created by fetch_baby_names.rb)
│   └── cache/
│       └── census_age_sex.xlsx  # Downloaded Census file (cached)
├── Gemfile                      # Dependencies
├── .rubocop.yml                 # Code style configuration
└── README.md                    # This file
```

## Development

### Running Tests

Run the test suite:

```bash
ruby test/test_average_american.rb
```

Tests use fixture data from `test/fixtures/` and don't require fetching real Census data.

All tests should pass before committing changes.

### Code Style

Check code style with rubocop:

```bash
bundle exec rubocop
```

Fix any violations before committing.

### How It Works

1. **Census Data Fetching**: Downloads the Census Excel file and caches it locally
2. **Census Parsing**: Extracts gender distribution and median age for each year (2020-2024)
3. **Baby Name Parsing**: Parses NationalNames.csv to find most popular names by year and gender
4. **Calculation**:
   - **Gender**: Mode (most common) - calculated from total population by gender
   - **Age**: Median age as reported by Census Bureau
   - **Name**: Determined by:
     - Birth year = current year - median age
     - Most popular name for that birth year and gender
5. **Output**: Formats the data into a readable profile for each year

## Methodology

Following John Green's approach:
- **Gender**: Uses mode (most common value) from the gender distribution
- **Age**: Uses median age from Census data
- **Name**: Uses the most popular baby name from the calculated birth year
  - Example: If median age is 39.1 in 2024, birth year ≈ 1985
  - For females born in 1985, the most popular name was Jessica
- Data is specific to the United States population

## Current Demographics

Implemented characteristics:
- ✅ Gender (mode from population distribution)
- ✅ Age (median)
- ✅ Name (most popular for birth year and gender)

## Future Enhancements

Potential additions based on the original idea:
- Income (median household income)
- Political affiliation
- Religion
- Education level
- Marital status
- Number of children
- Employment status
- State filtering
- Tax burden by state

## License

This project is open source and available for educational purposes.

## Credits

Inspired by John Green's video analysis. Data sourced from:
- U.S. Census Bureau (demographic data)
- Social Security Administration via Kaggle (baby names)
