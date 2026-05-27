suppressPackageStartupMessages({ library(tidyverse) })

RATING_DIR <- "C:/Users/50560/Desktop/cms_analysis/1. Experiment_Result/Rating&LSG Timing"
f <- file.path(RATING_DIR, "P03_24_04_2026.dat")

lines  <- read_lines(f, locale = locale(encoding = "UTF-8"))
data_lines <- lines[str_starts(lines, "Split_")]
cat(sprintf("Total data lines in P03: %d\n", length(data_lines)))

# Print raw line 16 (0-based index 15)
raw <- data_lines[16]
cat(sprintf("\nLine 16 raw repr: %s\n", deparse(raw)))

parts <- str_split(raw, "\t")[[1]]
parts_clean <- str_trim(parts[parts != ""])
cat(sprintf("Parts after split+trim: %s\n", paste(deparse(parts_clean), collapse=" ")))
cat(sprintf("seqname = %s\n", deparse(parts_clean[1])))
cat(sprintf("nchar(seqname) = %d\n", nchar(parts_clean[1])))
cat(sprintf("Bytes: %s\n", paste(chartr("", "", chartr("\n\r\t","NRT", parts_clean[1])), collapse="")))

# Test regex
s <- str_remove(parts_clean[1], "\\.bgr$")
cat(sprintf("\nAfter .bgr removal: %s\n", deparse(s)))
m <- str_match(s, "^Split_([ABC])_112_L1_F(\\d)_(.+)_$")
cat(sprintf("str_match result: %s\n", paste(m, collapse="|")))
