setwd("D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock")
res <- devtools::test(reporter = "progress")
df <- as.data.frame(res)
cat(sprintf("\nTOTAL: passed %d, failed %d, warnings %d, skipped %d\n",
            sum(df$passed), sum(df$failed), sum(df$warning), sum(df$skipped)))
if (sum(df$failed) > 0) quit(status = 1)
