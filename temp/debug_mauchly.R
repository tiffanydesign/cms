suppressPackageStartupMessages({ library(tidyverse); library(rstatix); library(here) })
source(here::here("R","00_setup.R"))
master <- read_csv(here::here("output","master_long.csv"), show_col_types=FALSE) %>%
  mutate(frequency=factor(frequency,levels=FREQ_LEVELS))
step1 <- master %>% group_by(participant_id,frequency) %>%
  summarise(TTC_s=mean(TTC_s,na.rm=TRUE),.groups="drop")
rt <- rstatix::anova_test(data=step1, dv="TTC_s", wid="participant_id", within="frequency", effect.size="pes")
cat("Names:", paste(names(rt), collapse=", "), "\n")
mc <- rt[["Mauchly's test for sphericity"]]
cat("Mauchly cols:", paste(names(mc), collapse=", "), "\n")
print(mc)
sc <- rt[["Sphericity Corrections"]]
cat("SphCor cols:", paste(names(sc), collapse=", "), "\n")
print(sc)
