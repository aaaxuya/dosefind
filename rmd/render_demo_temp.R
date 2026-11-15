Sys.setlocale("LC_CTYPE", "Chinese_China.utf8")
Sys.setenv(RSTUDIO_PANDOC = "D:/statistic_relative/yinyong/Rstudio/resources/app/bin/quarto/bin/tools")
demo_env <- new.env(parent = globalenv())
rmarkdown::render("rmd/uniDoseFind演示.rmd", encoding = "UTF-8", quiet = TRUE, envir = demo_env)
cat("All chunks rendered. Package:", as.character(packageVersion("UnifiedDoseFinding")), "\n")
for (nm in c("oc_rq", "oc_qcrm", "oc_qb", "oc_ib", "oc_ic", "oc_tb", "oc_gc")) {
  x <- get(nm, demo_env)
  stopifnot(length(x$selpercent) == 6, all(is.finite(x$selpercent)), all(is.finite(x$nptsdose)))
  cat(nm, "selection total", sum(x$selpercent), "mean N", sum(x$nptsdose), "\n")
}
