# Potential outcomes indexed by enrollment position x dose x trial.
# Outcomes at different doses are independently drawn, following legacy.
generate_bank <- function(ptox, nmax, ntrial) {
  bank <- array(NA_integer_, dim = c(nmax, ncol(ptox), ntrial))
  for (dose in seq_len(ncol(ptox))) {
    draws <- stats::rmultinom(n = nmax * ntrial, size = 1L, prob = ptox[, dose])
    grade <- max.col(t(draws), ties.method = "first") - 1L
    bank[, dose, ] <- matrix(grade, nrow = nmax, ncol = ntrial)
  }
  bank
}

validate_pcs_settings <- function(settings) {
  positive_integer <- function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x) && x >= 1 && x == floor(x)
  }
  for (key in c("ntrial", "ncohort", "cohortsize", "startdose")) {
    if (!positive_integer(settings[[key]])) stop(key, " must be a positive integer.")
  }
  if (!is.numeric(settings$seed) || length(settings$seed) != 1L ||
      !is.finite(settings$seed) || settings$seed < 0 ||
      settings$seed > .Machine$integer.max || settings$seed != floor(settings$seed)) {
    stop("seed must be an integer in [0, .Machine$integer.max].")
  }
  score <- settings$score_raw
  if (!is.numeric(score) || length(score) < 2L || any(!is.finite(score)) ||
      any(score < 0) || any(diff(score) < 0) || max(score) <= 0) {
    stop("score_raw must be nonnegative, nondecreasing, with positive maximum.")
  }
  target <- settings$target_raw
  if (!is.numeric(target) || length(target) != 1L || !is.finite(target) ||
      target <= 0 || target >= max(score)) {
    stop("target_raw must be strictly between 0 and max(score_raw).")
  }
  lower <- settings$gboin_mu_1_multiplier
  upper <- settings$gboin_mu_2_multiplier
  scalar_finite <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!scalar_finite(lower) || !scalar_finite(upper) || lower < 0 || lower >= 1 || upper <= 1) {
    stop("gBOIN multipliers must satisfy 0 <= mu_1_multiplier < 1 < mu_2_multiplier.")
  }
  scenarios <- settings$scenarios
  if (!is.list(scenarios) || !length(scenarios) || is.null(names(scenarios)) ||
      anyNA(names(scenarios)) || any(!nzchar(names(scenarios))) || anyDuplicated(names(scenarios))) {
    stop("scenarios must be a nonempty list with unique, nonempty names.")
  }
  for (name in names(scenarios)) {
    p <- scenarios[[name]]
    if (!is.matrix(p) || !is.numeric(p) || nrow(p) != length(score) ||
        ncol(p) < 1L || ncol(p) >= 99L || any(!is.finite(p)) ||
        any(p < 0 | p > 1) || any(abs(colSums(p) - 1) > 1e-10)) {
      stop(name, ": ptox must contain grade probabilities summing to 1 per dose.")
    }
    if (any(diff(as.vector(score %*% p)) < -1e-10)) {
      stop(name, ": true mean toxicity must be nondecreasing across doses.")
    }
    if (settings$startdose > ncol(p) || length(settings$skeleton_qcrm) != ncol(p) ||
        !is.matrix(settings$skeletons_rqcrm) || ncol(settings$skeletons_rqcrm) != ncol(p)) {
      stop(name, ": startdose and skeleton dimensions must match the doses.")
    }
  }
  invisible(settings)
}

generate_pcs_input <- function(settings) {
  validate_pcs_settings(settings)
  set.seed(settings$seed)
  banks <- lapply(settings$scenarios, generate_bank,
                  nmax = settings$ncohort * settings$cohortsize,
                  ntrial = settings$ntrial)
  list(settings = settings, banks = banks, rng_kind = RNGkind(),
       r_version = R.version.string)
}
