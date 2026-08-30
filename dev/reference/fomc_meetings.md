# Scheduled FOMC meetings 2021-2027

Decision dates (second day of the two-day meeting) of the scheduled FOMC
meetings, with a flag for meetings accompanied by a Summary of Economic
Projections and press conference. Unscheduled meetings and notation
votes are excluded. Companion calendar for
[`q_from_ffutures()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_ffutures.md).

## Usage

``` r
fomc_meetings
```

## Format

A tibble with 56 rows and 3 columns:

- decision_date:

  Decision day (`Date`).

- year:

  Calendar year (integer).

- sep:

  `TRUE` for meetings with a Summary of Economic Projections.

## Source

Federal Reserve Board, "Meeting calendars and information",
<https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm>
(retrieved 2026-08-30).

## Examples

``` r
data(fomc_meetings)
subset(fomc_meetings, year == 2024)
#> # A tibble: 8 × 3
#>   decision_date  year sep  
#>   <date>        <int> <lgl>
#> 1 2024-01-31     2024 FALSE
#> 2 2024-03-20     2024 TRUE 
#> 3 2024-05-01     2024 FALSE
#> 4 2024-06-12     2024 TRUE 
#> 5 2024-07-31     2024 FALSE
#> 6 2024-09-18     2024 TRUE 
#> 7 2024-11-07     2024 FALSE
#> 8 2024-12-18     2024 TRUE 
```
