# Typical revision of the event probability

Folded-normal approximation of the expected absolute revision of the
event probability until resolution: \\E\|q_T - q\| \approx
q(1-q)\sqrt{2A/\pi}\\.

## Usage

``` r
ec_revision(q, A)
```

## Arguments

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

Numeric vector.

## Examples

``` r
# Brexit two weeks out: about 5 probability points
ec_revision(0.195, 0.166)
#> [1] 0.05102989
```
