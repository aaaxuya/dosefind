# Defaults: legacy/unifiDoseF/try_bank.R and UnifiedDoseFinding 0.1.10.
settings <- list(
  output_dir = "results/pcs_comparison",
  seed = 2026L,
  ntrial = 4000L,
  cohortsize = 3L,
  ncohort = 10L,
  startdose = 1L,
  n.earlystop = 100L,
  score_raw = c(0, 0.5, 1, 1.5),
  target_raw = 0.47,
  cutoff.eli = 0.90, # CRM methods only; original gBOIN has no such rule
  mselection = 1L, # RQ-CRM: 1 = model selection; 2 = model averaging
  skeleton_qcrm = c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85),
  skeletons_rqcrm = rbind(
    c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85),
    c(0.05, 0.10, 0.15, 0.25, 0.40, 0.65),
    c(0.20, 0.40, 0.60, 0.75, 0.85, 0.95)
  ),
  # Original gBOIN defaults: mu_1 = 0.6 * target, mu_2 = 1.4 * target.
  # Both refer to RAW scores. Allocation boundaries are arithmetic midpoints.
  gboin_mu_1_multiplier = 0.6,
  gboin_mu_2_multiplier = 1.4,
  keep.patient.data = FALSE,
  # Rows: grades 0:3; columns: doses 1:6. Add named matrices for more scenarios.
  scenarios = list(
    legacy_example = rbind(
      c(0.83, 0.75, 0.62, 0.51, 0.34, 0.19),
      c(0.12, 0.15, 0.18, 0.19, 0.16, 0.11),
      c(0.04, 0.07, 0.11, 0.14, 0.15, 0.11),
      c(0.01, 0.03, 0.09, 0.16, 0.35, 0.59)
    )
  )
)
