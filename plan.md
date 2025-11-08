# Average American - Implementation Plan

## Goal
Create a simple Ruby command-line script that constructs the "average/median American" based on demographic data, with the ability to filter by year, state, political party, etc.

## Architecture: Keep It Simple

### Single Ruby Script Approach
- Main file: `average_american.rb` - executable Ruby script
- Data directory: `data/` - store cached/downloaded data as JSON or CSV files
- Simple execution: `ruby average_american.rb --state=Ohio --year=2023`

### Core Components (within single script)

1. **Data Sources Module**
   - Methods to fetch/load data from:
     - Pew Research (demographics, political, religious data)
     - Gallup (identity, polling data)
     - WalletHub (state tax burden)
     - Fool.com / IRS (federal tax averages)
   - Cache data locally in `data/` directory to avoid repeated fetches
   - Parse HTML/JSON as needed

2. **Demographic Characteristics**
   - Gender (mode: most common)
   - Age (median)
   - Income (median)
   - Tax burden (average by state)
   - Political affiliation (mode)
   - Religion (mode)
   - Education level (mode)
   - Marital status (mode)
   - Children (median/mode)
   - Employment status (mode)
   - Add more based on available data

3. **Calculation Logic**
   - Filter datasets based on user parameters (year, state, party, etc.)
   - Calculate median for continuous variables (age, income)
   - Calculate mode for categorical variables (gender, religion, politics)
   - Handle missing data gracefully

4. **Parameter System**
   - Command-line arguments:
     - `--year=YYYY` - filter to specific year
     - `--state=STATE` - filter to specific state
     - `--party=PARTY` - filter to political affiliation
     - `--income=RANGE` - filter to income bracket
   - Default: national median across all available data

5. **Output Format**
   - Simple text description, like:
     ```
     The Average American (2023):
     - Gender: Female
     - Age: 38 years old
     - Lives in: Ohio (if state specified)
     - Income: $54,132 per year
     - Pays: $8,300 in taxes annually (15.3%)
     - Political affiliation: Independent
     - Religion: Christian (Protestant)
     - Education: Some college
     - Marital status: Married
     - Children: 2
     ```

## Implementation Steps

1. **Phase 1: Project Setup**
   - Create `Gemfile` with dependencies (rubocop, minitest if needed)
   - Create `.rubocop.yml` configuration
   - Set up `test/` directory structure
   - Create initial test file
   - Run `bundle install`

2. **Phase 2: Basic Structure**
   - Create `average_american.rb` with basic argument parsing
   - Write tests for argument parsing
   - Run tests and rubocop, fix any issues
   - Set up `data/` directory structure
   - Create methods to load/save cached data
   - Write tests for data loading/saving
   - Run tests and rubocop, fix any issues

3. **Phase 3: Core Calculation Logic**
   - Implement median calculation function
   - Write tests for median calculation
   - Run tests and rubocop, fix any issues
   - Implement mode calculation function
   - Write tests for mode calculation
   - Run tests and rubocop, fix any issues

4. **Phase 4: Data Acquisition**
   - Start with 1-2 data sources (e.g., Pew Research)
   - Download and cache sample datasets
   - Write parsers for each data source format
   - Write tests for data parsing
   - Run tests and rubocop, fix any issues
   - **Note**: May need to manually download some data files since not all sources have APIs

5. **Phase 5: Filtering & Building**
   - Build filtering logic for parameters
   - Write tests for filtering
   - Run tests and rubocop, fix any issues
   - Create the "average person" builder that combines all characteristics
   - Write tests for person builder
   - Run tests and rubocop, fix any issues

6. **Phase 6: Output**
   - Format the text description
   - Write tests for output formatting
   - Run tests and rubocop, fix any issues
   - Make it readable and match John Green's style

7. **Phase 7: Refinement**
   - Add more data sources and characteristics
   - Improve parameter combinations
   - Handle edge cases
   - Ensure all tests pass and rubocop is clean

## Technical Decisions

- **Dependencies**: Minimal - maybe just `nokogiri` for HTML parsing if needed
- **Testing**: Use `minitest` (Ruby standard library) for unit tests
- **Linting**: Use `rubocop` for code style and quality
- **Data Storage**: Simple JSON or CSV files in `data/` directory
- **Data Freshness**: Manual updates for now (could add auto-fetch later)
- **Error Handling**: Graceful degradation - if data missing for a characteristic, skip it

## Development Workflow

**Test-Driven Development Approach:**
1. Write tests first or alongside each feature
2. Run tests after every change: `ruby test/test_average_american.rb`
3. Run rubocop after every change: `rubocop`
4. All tests must pass before moving to next feature
5. All rubocop violations must be fixed before moving to next feature

**Project Structure:**
```
average-american/
├── average_american.rb    # Main script
├── test/
│   └── test_average_american.rb  # Test suite
├── data/                  # Cached data files
│   ├── pew/
│   ├── gallup/
│   └── ...
├── Gemfile                # Dependencies
├── .rubocop.yml           # Rubocop configuration
└── README.md
```

**Testing Strategy:**
- Test calculation functions (median, mode)
- Test filtering logic with sample data
- Test data parsing/loading
- Test output formatting
- Use fixtures for test data in `test/fixtures/`

**Rubocop Configuration:**
- Start with default rules
- Adjust as needed for script-style Ruby code
- Focus on readability and maintainability

## Data Source Strategy

Some sources will require manual data download:
- Download CSV/Excel files from Pew Research datasets
- Convert to JSON for easier parsing
- Store in `data/pew/`, `data/gallup/`, etc.

Others might be scrapable:
- Use simple HTTP requests + Nokogiri for parsing

## Example Usage

```bash
# National average
ruby average_american.rb

# Average Ohioan in 2023
ruby average_american.rb --state=Ohio --year=2023

# Average Democrat
ruby average_american.rb --party=Democrat

# Average Californian making $75k-$100k
ruby average_american.rb --state=California --income=75000-100000
```

## Open Questions

1. Should we include data download automation, or expect manual data file placement?
2. What's the priority order for characteristics if we can't get all data sources working?
3. Do we want JSON output option in addition to text?
