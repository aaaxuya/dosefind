# All methods read bank[enrollment_position, dose, trial].
# True probabilities are not passed to the allocation functions.
run_pcs_comparison <- function(input) {
  if (!requireNamespace("UnifiedDoseFinding", quietly = TRUE)) {
    stop('Install UnifiedDoseFinding first: install.packages("UnifiedDoseFinding")')
  }
  version <- as.character(utils::packageVersion("UnifiedDoseFinding"))
  if (version != "0.1.10") {
    warning("Reference version is UnifiedDoseFinding 0.1.10; installed version: ", version)
  }
  cfg <- input$settings
  if (is.null(cfg$gboin_mu_1_multiplier) || is.null(cfg$gboin_mu_2_multiplier)) {
    stop("Saved input uses the old gBOIN configuration; rerun scripts/01_generate.R.")
  }
  results <- lapply(names(input$banks), function(scenario) {
    message("Running scenario: ", scenario)
    common <- list(
      bank = input$banks[[scenario]], ncohort = cfg$ncohort, cohortsize = cfg$cohortsize,
      n.earlystop = cfg$n.earlystop,
      ntrial = cfg$ntrial, keep.patient.data = cfg$keep.patient.data
    )
    crm_args <- c(common, list(cutoff.eli = cfg$cutoff.eli,
                               target = cfg$target_raw, score = cfg$score_raw,
                               start.dose = cfg$startdose))
    rqcrm <- do.call(get_oc_RQ_CRM_bank, c(crm_args, list(
      skeletons = cfg$skeletons_rqcrm, mselection = cfg$mselection)))
    qcrm <- do.call(get_oc_RQ_CRM_bank, c(crm_args, list(skeletons = cfg$skeleton_qcrm)))
    gboin <- do.call(get_oc_gBOIN_bank, c(common, list(
      target = cfg$target_raw, score = cfg$score_raw,
      startdose = cfg$startdose,
      mu_1 = cfg$gboin_mu_1_multiplier * cfg$target_raw,
      mu_2 = cfg$gboin_mu_2_multiplier * cfg$target_raw)))
    list("RQ-CRM" = rqcrm, "Quasi-CRM" = qcrm, "gBOIN" = gboin)
  })
  names(results) <- names(input$banks)
  list(settings = cfg, results = results, package_version = version,
       session_info = utils::sessionInfo())
}
