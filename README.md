# Average American

A Ruby command-line tool that constructs a profile of the "average American" based on demographic data from the U.S. Census Bureau. Inspired by [John Green's video "I Was Wrong about the Average American"](https://www.youtube.com/watch?v=tEDXVGHW4Gg).

## Features

- Fetches and parses real demographic data from the U.S. Census Bureau
- Calculates median age (overall and gender-specific) and gender distribution (mode)
- Determines most popular baby name based on gender and implied birth year
- Shows a table of 3 profiles (Average American, Average Man, Average Woman) across all available years
- Supports filtering by specific year (1990-2024, excluding 2020)
- Supports filtering by gender (male or female)
- Combines historical Census data (1990-2009) with ACS API data (2010-2024)
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

**Required before first use:** Fetch the latest Census data from the ACS API:

```bash
ruby average_american.rb --fetch
```

This will:
- Load historical Census data for years 1990-2009 from compiled Census Bureau sources
- Fetch demographic data from the Census Bureau's American Community Survey (ACS) 1-Year API for years 2010-2024
- Note: 2020 ACS 1-year data was not published due to COVID-19
- Save all data to `data/census_parsed.json`

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

Output (showing first few and last few years of the 34-year span):
```
 Year  |           Average American            |        Average Man         |       Average Woman
       |     Name      Gender    Age    Birth  |     Name      Age   Birth  |     Name      Age   Birth
-----------------------------------------------------------------------------------------------------------
 1990  |     Mary      Female    32.8    1957  |   Michael     31.6   1958  |     Mary      34.0   1956
 1991  |     Mary      Female    32.8    1958  |   Michael     31.6   1959  |     Mary      34.0   1957
 1992  |     Mary      Female    32.9    1959  |    David      31.9   1960  |     Mary      34.0   1958
 ...
 2022  |   Jennifer    Female    39.0    1983  |   Michael     37.9   1984  |   Jennifer    40.1   1982
 2023  |   Jennifer    Female    39.2    1984  |   Michael     38.1   1985  |   Jennifer    40.3   1983
 2024  |   Jessica     Female    39.2    1985  |   Michael     38.1   1986  |   Jennifer    40.3   1984
```

The table shows three profiles for each year, including their calculated birth year:
1. **The Average American**: Gender determined by mode (most common), age from overall median, name based on that gender/age
2. **The Average Man**: Gender fixed to Male, age from male-specific median, name based on Male/age
3. **The Average Woman**: Gender fixed to Female, age from female-specific median, name based on Female/age

The **Birth** column shows the calculated birth year (current year - median age), which is used to determine the most popular name for that cohort.

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

- **Census Bureau**: Age and gender data from multiple Census sources:
  - **Historical (1990-2009)**: Compiled from Census Population Estimates and Decennial Census data
    - 1990-2000 estimates from [Census Population Estimates](https://www2.census.gov/programs-surveys/popest/tables/1990-2000/national/totals/)
    - 2000-2010 intercensal estimates from Census Bureau historical tables
  - **Modern (2010-2024)**: [American Community Survey (ACS) 1-Year Estimates API](https://www.census.gov/data/developers/data-sets/acs-1year.html)
    - Table B01002: Median Age by Sex
    - Table B01001: Sex by Age (for population counts)
    - Note: 2020 excluded (not published due to COVID-19)
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
│   ├── census_parsed.json       # Census data from ACS API (created by --fetch)
│   └── baby_names.json          # Parsed baby names (created by fetch_baby_names.rb)
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

1. **Census Data Fetching**: Combines historical and modern data
   - **1990-2009**: Historical median ages from Census Bureau population estimates
   - **2010-2024**: Live data from ACS 1-Year Estimates API
     - Table B01002 for median age by sex
     - Table B01001 for population counts by sex
     - 2020 excluded (not published due to COVID-19)
2. **Baby Name Parsing**: Parses NationalNames.csv to find most popular names by year and gender
3. **Calculation**:
   - **Gender**: Mode (most common) - calculated from total population by gender
   - **Age**: Median age as reported by Census
   - **Birth Year**: Calculated as current year - median age
   - **Name**: Determined by:
     - Most popular name for the calculated birth year and gender
4. **Output**: Formats the data into a readable table spanning 34 years (1990-2024)

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
