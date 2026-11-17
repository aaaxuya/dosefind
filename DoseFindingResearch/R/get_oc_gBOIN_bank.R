# Bank adapter for UnifiedDoseFinding's actual gBOIN implementation.
# Allocation and final selection call the package's public functions directly.
# Reference: get_oc_gBOIN_continuous (UnifiedDoseFinding 0.1.10).
# The only outcome-generation change is replacing its rnorm draws with the
# shared bank's observed grade scores. Use RAW score/target units throughout.
get_oc_gBOIN_bank <- function(
    bank, target, score, ncohort = floor(dim(bank)[1L] / cohortsize),
    cohortsize = 3L, n.earlystop = 100, startdose = 1L,
    mu_1 = 0.6 * target, mu_2 = 1.4 * target,
    ntrial = dim(bank)[3L], keep.patient.data = FALSE) {
  if (!requireNamespace("UnifiedDoseFinding", quietly = TRUE)) {
    stop("UnifiedDoseFinding is required for gBOIN.", call. = FALSE)
  }
  positive_integer <- function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x) && x >= 1 && x == floor(x)
  }
  dims <- dim(bank)
  if (!is.numeric(bank) || length(dims) != 3L || any(dims < 1L) || dims[2L] >= 99L) {
    stop("bank must be a numeric patient x dose x trial array with fewer than 99 doses.")
  }
  if (!is.numeric(score) || !is.null(dim(score)) || length(score) < 2L ||
      any(!is.finite(score)) || any(score < 0) || any(diff(score) < 0) || max(score) <= 0) {
    stop("score must be nonnegative, nondecreasing, with positive maximum.")
  }
  if (any(!is.finite(bank)) || any(bank != floor(bank)) ||
      any(bank < 0 | bank >= length(score))) {
    stop("bank must contain integer grades from 0 to length(score) - 1.")
  }
  for (x in list(ncohort, cohortsize, startdose, ntrial)) {
    if (!positive_integer(x)) stop("Cohort counts, startdose and ntrial must be positive integers.")
  }
  if (ncohort * cohortsize > dims[1L] || ntrial > dims[3L] || startdose > dims[2L]) {
    stop("Requested patients, trials or startdose exceed bank dimensions.")
  }
  if (!is.numeric(n.earlystop) || length(n.earlystop) != 1L || is.na(n.earlystop) ||
      n.earlystop <= 6 || (is.finite(n.earlystop) && n.earlystop != floor(n.earlystop))) {
    stop("n.earlystop must be an integer greater than 6, or Inf.")
  }
  scalar_finite <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!scalar_finite(target) || !scalar_finite(mu_1) || !scalar_finite(mu_2) ||
      target <= 0 || mu_1 < 0 || mu_1 >= target || mu_2 <= target) {
    stop("Require 0 <= mu_1 < target < mu_2 in raw score units.")
  }
  if (!is.logical(keep.patient.data) || length(keep.patient.data) != 1L || is.na(keep.patient.data)) {
    stop("keep.patient.data must be TRUE or FALSE.")
  }
  ndose <- dims[2L]
  N <- Y <- matrix(0, nrow = ntrial, ncol = ndose)
  dselect <- integer(ntrial)
  stop.reason <- rep("max_sample", ntrial)
  patient.data <- if (keep.patient.data) vector("list", ntrial) else NULL
  for (trial in seq_len(ntrial)) {
    n <- y <- numeric(ndose)
    d <- startdose
    records <- if (keep.patient.data) vector("list", ncohort) else NULL
    for (cohort in seq_len(ncohort)) {
      patients <- (cohort - 1L) * cohortsize + seq_len(cohortsize)
      observed <- bank[patients, d, trial]
      observed_score <- score[observed + 1L]
      y[d] <- y[d] + sum(observed_score)
      n[d] <- n[d] + cohortsize
      if (keep.patient.data) {
        records[[cohort]] <- data.frame(
          trial = trial, patient = patients, cohort = cohort,
          dose = d, grade = observed, score = observed_score)
      }
      # Same stopping order as get_oc_gBOIN_continuous: before next allocation.
      if (n[d] >= n.earlystop) {
        stop.reason[trial] <- "n.earlystop"
        break
      }
      d <- UnifiedDoseFinding::next_gBOIN_continuous(
        target = target, n = n, y = y, d = d, mu_1 = mu_1, mu_2 = mu_2)
    }
    dselect[trial] <- UnifiedDoseFinding::select_mtd_gBOIN_continuous(
      target = target, npts = n, ntox = y)
    N[trial, ] <- n
    Y[trial, ] <- y
    if (keep.patient.data) patient.data[[trial]] <- do.call(rbind, records)
  }
  list(
    method = "gBOIN", implementation = "UnifiedDoseFinding gBOIN_continuous with bank scores",
    score_scale = "raw", target = target, score = score,
    mu_1 = mu_1, mu_2 = mu_2,
    lambda_e = (target + mu_1) / 2, lambda_d = (target + mu_2) / 2,
    ncohort = ncohort, cohortsize = cohortsize, startdose = startdose,
    n.earlystop = n.earlystop, ntrial = ntrial,
    selpercent = tabulate(dselect, nbins = ndose) / ntrial * 100,
    nptsdose = colMeans(N), ntoxdose = colMeans(Y),
    no_mtd_percent = mean(dselect == 99L) * 100,
    N = N, Y = Y, dselect = dselect, stop.reason = stop.reason,
    patient.data = if (keep.patient.data) do.call(rbind, patient.data) else NULL
  )
}