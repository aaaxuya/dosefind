library(UnifiedDoseFinding)
cat("Version:", as.character(packageVersion("UnifiedDoseFinding")), "\n")
for (nm in c("next_RQ_CRM", "select_mtd_RQ_CRM", "next_QuasiBOIN", "select_mtd_Ivanova_continuous")) {
  cat("\n", nm, "\n"); print(getExportedValue("UnifiedDoseFinding", nm))
}
cat("\nReferences\n")
db <- tools::Rd_db("UnifiedDoseFinding")
for (nm in c("get_oc_RQ_CRM.Rd", "get_oc_gBOIN_TB.Rd", "get_oc_Ivanova_binary.Rd")) {
  rd <- db[[nm]]
  for (part in rd) if (identical(attr(part, "Rd_tag"), "\\references")) cat(unlist(part))
}
