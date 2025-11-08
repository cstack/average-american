# Average American

A Ruby command-line tool that constructs a profile of the "average American" based on demographic data from the U.S. Census Bureau. Inspired by [John Green's video "I Was Wrong about the Average American"](https://www.youtube.com/watch?v=tEDXVGHW4Gg).

## Features

- Fetches and parses real demographic data from the U.S. Census Bureau
- Calculates median age and gender distribution (mode)
- Supports filtering by year (2020-2024)
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

### Fetch Census Data

First, download and parse the latest Census data:

```bash
ruby average_american.rb --fetch
```

This will:
- Download the Census Excel file from census.gov
- Parse demographic data for years 2020-2024
- Save the parsed data to `data/census_parsed.json`

### Show Average American Profile

Show the average American for the latest available year:

```bash
ruby average_american.rb
```

Output:
```
The Average American:
- Gender: Female
- Age: 39.1 years old
(Year: latest)
```

### Filter by Year

Show the average American for a specific year:

```bash
ruby average_american.rb --year=2020
ruby average_american.rb --year=2023
```

Output:
```
The Average American:
- Gender: Female
- Age: 38.5 years old
(Year: 2020)
```

### Help

Show help message:

```bash
ruby average_american.rb --help
```

## Data Sources

- **Census Bureau**: Age and gender data from [Annual Estimates of the Resident Population](https://www2.census.gov/programs-surveys/popest/tables/2020-2024/national/asrh/nc-est2024-agesex.xlsx)

## Project Structure

```
average-american/
├── average_american.rb          # Main script with all modules
├── test/
│   └── test_average_american.rb # Test suite
├── data/
│   ├── demographics.json        # Static fallback data
│   ├── census_parsed.json       # Parsed Census data (after --fetch)
│   └── cache/
│       └── census_age_sex.xlsx  # Downloaded Census file
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

All tests should pass before committing changes.

### Code Style

Check code style with rubocop:

```bash
bundle exec rubocop
```

Fix any violations before committing.

### How It Works

1. **Data Fetching**: Downloads the Census Excel file and caches it locally
2. **Parsing**: Extracts gender distribution and median age for each year (2020-2024)
3. **Calculation**:
   - Gender: Mode (most common) - calculated from total population by gender
   - Age: Median age as reported by Census Bureau
4. **Output**: Formats the data into a readable profile

## Methodology

Following John Green's approach:
- **Gender**: Uses mode (most common value) from the gender distribution
- **Age**: Uses median age from Census data
- Data is specific to the United States population

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

Inspired by John Green's video analysis. Data sourced from the U.S. Census Bureau.
