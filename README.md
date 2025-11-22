# Average American

A Ruby command-line tool that constructs a profile of the "average American" based on demographic data from the U.S. Census Bureau. Inspired by [John Green's video "I Was Wrong about the Average American"](https://www.youtube.com/watch?v=tEDXVGHW4Gg).

## Features

- Fetches and parses real demographic data from the U.S. Census Bureau
- Calculates median age (overall and gender-specific) and gender distribution (mode)
- Determines most popular baby name based on gender and implied birth year
- Shows a table of 3 profiles (Average American, Average Man, Average Woman) across all available years
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

After fetching data, the default behavior shows a table of 3 profiles for all available years:

```bash
ruby average_american.rb
```

Output:
```
 Year  |         Average American         |      Average Man       |     Average Woman
       |     Name      Gender    Age    |     Name      Age   |     Name      Age
-----------------------------------------------------------------------------------------------
 2020  |   Jennifer    Female    38.5   |   Michael     37.5  |   Jennifer    39.6
 2021  |   Jennifer    Female    38.8   |   Michael     37.7  |   Jennifer    39.8
 2022  |   Jennifer    Female    38.9   |   Michael     37.8  |   Jennifer    40.0
 2023  |   Jennifer    Female    39.0   |   Michael     37.9  |   Jennifer    40.1
 2024  |   Jessica     Female    39.1   |   Michael     38.1  |   Jennifer    40.2
```

The table shows three profiles for each year:
1. **The Average American**: Gender determined by mode (most common), age from overall median, name based on that gender/age
2. **The Average Man**: Gender fixed to Male, age from male-specific median, name based on Male/age
3. **The Average Woman**: Gender fixed to Female, age from female-specific median, name based on Female/age

### Show a Specific Year

Show 3 profiles for a specific year:

```bash
ruby average_american.rb --year=2023
```

Output:
```
The Average American:
- Name: Jennifer
- Gender: Female
- Age: 39.0 years old

--------------------------------------------------

The Average American Man:
- Name: Michael
- Gender: Male
- Age: 37.9 years old

--------------------------------------------------

The Average American Woman:
- Name: Jennifer
- Gender: Female
- Age: 40.1 years old
(Year: 2023)
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

Following John Green's approach with conditional probability:

**The Average American** (unconditional):
- **Gender**: Mode (most common value) from the gender distribution
- **Age**: Median age from overall population
- **Name**: Most popular baby name for the determined gender and birth year

**The Average Man/Woman** (conditional on gender):
- **Gender**: Fixed to Male or Female
- **Age**: Median age specific to that gender
- **Name**: Most popular baby name for that gender and birth year
  - Example: If median age for females is 39.6 in 2024, birth year ≈ 1984
  - For females born in 1984, the most popular name was Jessica

This approach properly handles conditional probability:
- The Average American uses overall statistics
- The Average Man/Woman uses gender-specific statistics, reflecting that conditioning on gender changes the age distribution
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
