# DTC Backend

This directory contains the backend infrastructure for the DTC (Direct-to-Consumer) scraping and data processing system.

## Overview

The backend consists of several components:
- **dbt**: Data transformation and modeling
- **Supabase**: Database and API layer
- **n8n**: Workflow automation

## DBT (Data Build Tool)

### What is DBT?

DBT (Data Build Tool) is an open-source tool that enables data analysts and engineers to transform data in their warehouse more effectively. It allows you to write SQL queries as models and run them in a specific order to build your data pipeline.

### Project Structure

```
dtc_dbt/
├── models/
│   ├── staging/          # Raw data cleaning and preparation
│   │   ├── stg_google_search_results.sql
│   │   ├── stg_google_search_organic_results.sql
│   │   └── schema.yml
│   └── marts/           # Business-level transformations
│       ├── google_search_instagram_profiles.sql
│       ├── dtc_profiles.sql
│       └── dtc_profile_keywords.sql
├── packages.yml         # External dependencies
├── dbt_project.yml      # Project configuration
└── profiles/           # Database connection settings
```

### Data Pipeline Overview

Our DBT pipeline transforms raw Google search results into structured Instagram profile data:

1. **Raw Data**: Google search results stored as JSON in `public.dtc_raw_google_search_results`
2. **Staging**: Clean and prepare raw data
3. **Marts**: Create business-ready tables for analysis

### Pipeline Steps

#### Step 1: Raw Data Source
- **Table**: `public.dtc_raw_google_search_results`
- **Content**: Raw JSON data from Google search scraper
- **Structure**: Each row represents one keyword search with JSON results in the `data` column

#### Step 2: Staging Models
- **Purpose**: To clean and prepare the raw data for transformation.
- **Models**:
    - `stg_google_search_results`: Takes the raw source and renames columns for clarity.
    - `stg_google_search_organic_results`: Expands the `organicResults` JSON array into individual rows and filters for only Instagram URLs.
- **Materialization**: These are built as `views` for efficiency, meaning they are just saved queries and do not store data themselves.

#### Step 3: Marts Models
- **Purpose**: To create the final, structured tables for business use.
- **Models**:
    - `google_search_instagram_profiles`: An intermediate model that parses the Instagram URLs from the staging layer to extract usernames.
    - `dtc_profiles`: The final table for unique Instagram profiles. It generates a unique, deterministic `id` (a surrogate key) for each username.
    - `dtc_profile_keywords`: A junction table that links each profile to the search keyword that discovered it.
- **Materialization**: These are built as `incremental` tables. This means dbt will only insert or update new records on subsequent runs, making the process much faster.

### Key Concepts

- **Surrogate Keys**: Instead of relying on the database's auto-incrementing integers, we generate our own unique IDs using the `dbt_utils.generate_surrogate_key()` macro. This makes our models self-contained, robust, and idempotent.
- **Incremental Models**: This materialization strategy is key to efficient data processing. On the first run, the table is built fully. On subsequent runs, only new rows are added, which is significantly faster than a full rebuild.

### How to Run

1.  **Install Dependencies**: From the `dtc_dbt` directory, run `dbt deps` to install packages like `dbt_utils`.
2.  **Run the Pipeline**: From the `dtc_dbt` directory, run `dbt run`.
    -   To force a full rebuild of all models from scratch, run `dbt run --full-refresh`. This is useful if a model's logic has changed or data has become corrupted.
3.  **Test Data Quality**: Run `dbt test` to execute any data tests defined in the `schema.yml` files (e.g., checking for nulls or duplicates). 