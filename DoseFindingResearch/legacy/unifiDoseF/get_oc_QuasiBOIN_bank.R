# Standalone: source this file directly; all helpers are local to the function.
# 使用 bank 的 Quasi-BOIN。
# 改写依据：UnifiedDoseFinding 0.1.10 get_oc_QuasiBOIN（GPL-2）；
# 原包作者：Chia-Wei Hsu、Haitao Pan、Rongji Mu。
# 与原包接口约定一致：score 必须在 [0, 1]，target 使用相同标准化尺度。
# 最终 MTD 选择调用原包公开函数 select_mtd_QuasiBOIN。

get_oc_QuasiBOIN_bank <- function(
    bank, target, score, ncohort = floor(dim(bank)[1L] / cohortsize),
    cohortsize = 3L, n.earlystop = 100, startdose = 1L,
    p.saf = 0.6 * target, p.tox = 1.4 * target, cutoff.eli = 0.95,
    extrasafe = FALSE, offset = 0.05, ntrial = dim(bank)[3L],
    keep.patient.data = FALSE) {
  .bank_positive_integer <- function(x, name) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
        x < 1 || x != floor(x)) {
      stop(name, " must be a positive integer.", call. = FALSE)
    }
  }

  .bank_probability <- function(x, name) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0 || x >= 1) {
      stop(name, " must be strictly between 0 and 1.", call. = FALSE)
    }
  }

  .bank_validate <- function(bank, score, cohortsize, ncohort, ntrial,
                             startdose, n.earlystop, cutoff.eli, keep.patient.data) {
    dims <- dim(bank)
    if (!is.numeric(bank) || length(dims) != 3L || any(dims < 1L)) {
      stop("bank must be a numeric array: patient x dose x trial.", call. = FALSE)
    }
    if (dims[2L] >= 99L) {
      stop("bank must have fewer than 99 doses; 99 denotes no MTD.", call. = FALSE)
    }
    if (!is.numeric(score) || !is.null(dim(score)) || length(score) < 2L ||
        any(!is.finite(score)) || any(score < 0) || any(diff(score) < 0) || max(score) <= 0) {
      stop("score must be a nonnegative, nondecreasing numeric vector with positive maximum.",
           call. = FALSE)
    }
    if (any(!is.finite(bank)) || any(bank != floor(bank)) ||
        any(bank < 0 | bank >= length(score))) {
      stop("bank must contain integer toxicity grades from 0 to length(score) - 1, without NA.",
           call. = FALSE)
    }
    .bank_positive_integer(cohortsize, "cohortsize")
    .bank_positive_integer(ncohort, "ncohort")
    .bank_positive_integer(ntrial, "ntrial")
    .bank_positive_integer(startdose, "startdose")
    if (ncohort * cohortsize > dims[1L]) {
      stop("bank has too few patients for ncohort * cohortsize.", call. = FALSE)
    }
    if (ntrial > dims[3L]) stop("ntrial exceeds the number of trials in bank.", call. = FALSE)
    if (startdose > dims[2L]) stop("start dose exceeds the number of doses in bank.", call. = FALSE)
    if (!is.numeric(n.earlystop) || length(n.earlystop) != 1L ||
        is.na(n.earlystop) || n.earlystop <= 6 ||
        (is.finite(n.earlystop) && n.earlystop != floor(n.earlystop))) {
      stop("n.earlystop must be an integer greater than 6, or Inf.", call. = FALSE)
    }
    .bank_probability(cutoff.eli, "cutoff.eli")
    if (!is.logical(keep.patient.data) || length(keep.patient.data) != 1L ||
        is.na(keep.patient.data)) {
      stop("keep.patient.data must be TRUE or FALSE.", call. = FALSE)
    }
    invisible(dims)
  }

  .bank_patient_data <- function(trial, doses, grades, cohortsize, score) {
    treated <- which(!is.na(doses))
    data.frame(
      trial = rep.int(trial, length(treated)),
      patient = treated,
      cohort = (treated - 1L) %/% cohortsize + 1L,
      dose = doses[treated],
      grade = grades[treated],
      score = score[grades[treated] + 1L]
    )
  }

  .bank_summarise <- function(N, Y, dselect, stop.reason, patient.data) {
    ndose <- ncol(N)
    ntrial <- nrow(N)
    list(
      selpercent = tabulate(dselect[dselect != 99L], nbins = ndose) / ntrial * 100,
      nptsdose = colMeans(N),
      ntoxdose = colMeans(Y),
      no_mtd_percent = mean(dselect == 99L) * 100,
      N = N,
      Y = Y,
      dselect = dselect,
      stop.reason = stop.reason,
      patient.data = if (is.null(patient.data)) NULL else do.call(rbind, patient.data)
    )
  }

  dims <- .bank_validate(bank, score, cohortsize, ncohort, ntrial,
                         startdose, n.earlystop, cutoff.eli, keep.patient.data)
  .bank_probability(target, "target")
  .bank_probability(p.saf, "p.saf")
  .bank_probability(p.tox, "p.tox")
  if (target < 0.05 || target > 0.6) {
    stop("Quasi-BOIN target must be between 0.05 and 0.6.", call. = FALSE)
  }
  if (max(score) > 1) {
    stop("Quasi-BOIN requires score in [0, 1]; normalize both score and target first.",
         call. = FALSE)
  }
  if (target - p.saf < 0.1 * target || p.tox - target < 0.1 * target) {
    stop("p.saf and p.tox must be separated from target by at least 0.1 * target.",
         call. = FALSE)
  }
  if (!is.logical(extrasafe) || length(extrasafe) != 1L || is.na(extrasafe)) {
    stop("extrasafe must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.numeric(offset) || length(offset) != 1L || !is.finite(offset) ||
      offset < 0 || offset >= 0.5 || (extrasafe && offset >= cutoff.eli)) {
    stop("offset must be in [0, 0.5), and below cutoff.eli when extrasafe = TRUE.",
         call. = FALSE)
  }
  if (!requireNamespace("UnifiedDoseFinding", quietly = TRUE)) {
    stop("UnifiedDoseFinding is required for final Quasi-BOIN MTD selection.", call. = FALSE)
  }

  ndose <- dims[2L]
  npts <- ncohort * cohortsize
  lambda.e <- log((1 - p.saf) / (1 - target)) /
    log(target * (1 - p.saf) / (p.saf * (1 - target)))
  lambda.d <- log((1 - target) / (1 - p.tox)) /
    log(p.tox * (1 - target) / (target * (1 - p.tox)))
  # 与原包一致：以整数毒性计数建立剔除边界，随后与累计等价毒性分数比较。
  b.elim <- vapply(seq_len(npts), function(n) {
    if (n < 3L) return(NA_real_)
    counts <- seq_len(n)
    excessive <- which(1 - stats::pbeta(target, counts + 1, n - counts + 1) > cutoff.eli)
    if (length(excessive)) counts[excessive[1L]] else NA_real_
  }, numeric(1L))
  b.e <- lambda.e * seq_len(npts)
  b.d <- lambda.d * seq_len(npts)
  has.elim <- !is.na(b.elim)
  b.d[has.elim] <- pmin(b.d[has.elim], b.elim[has.elim])

  N <- Y <- matrix(0, nrow = ntrial, ncol = ndose)
  dselect <- rep.int(99L, ntrial)
  stop.reason <- rep.int("max_sample", ntrial)
  patient.data <- if (keep.patient.data) vector("list", ntrial) else NULL
  for (trial in seq_len(ntrial)) {
    n <- y <- numeric(ndose)
    d <- startdose
    eliminated <- rep(FALSE, ndose)
    doses <- grades <- rep.int(NA_integer_, npts)
    for (cohort in seq_len(ncohort)) {
      patients <- (cohort - 1L) * cohortsize + seq_len(cohortsize)
      observed <- bank[patients, d, trial]
      doses[patients] <- d
      grades[patients] <- observed
      y[d] <- y[d] + sum(score[observed + 1L])
      n[d] <- n[d] + cohortsize

      if (!is.na(b.elim[n[d]]) && y[d] >= b.elim[n[d]]) {
        eliminated[d:ndose] <- TRUE
        if (d == 1L) {
          stop.reason[trial] <- "overtoxicity"
          break
        }
      }
      if (extrasafe && d == 1L && n[1L] >= 3L &&
          1 - stats::pbeta(target, y[1L] + 1, n[1L] - y[1L] + 1) > cutoff.eli - offset) {
        stop.reason[trial] <- "extrasafe"
        break
      }
      # 安全性检查优先于单剂量人数提前停止规则。
      if (n[d] >= n.earlystop) {
        stop.reason[trial] <- "n.earlystop"
        break
      }
      if (y[d] <= b.e[n[d]] && d < ndose) {
        if (!eliminated[d + 1L]) d <- d + 1L
      } else if (y[d] >= b.d[n[d]] && d > 1L) {
        d <- d - 1L
      }
    }
    if (!(stop.reason[trial] %in% c("overtoxicity", "extrasafe"))) {
      dselect[trial] <- UnifiedDoseFinding::select_mtd_QuasiBOIN(
        target = target, npts = n, ntox = y, cutoff.eli = cutoff.eli,
        extrasafe = extrasafe, offset = offset, print = FALSE
      )
    }
    N[trial, ] <- n
    Y[trial, ] <- y
    if (keep.patient.data) {
      patient.data[[trial]] <- .bank_patient_data(trial, doses, grades, cohortsize, score)
    }
  }
  c(list(method = "Quasi-BOIN", target = target, score = score,
         ncohort = ncohort, cohortsize = cohortsize, startdose = startdose,
         p.saf = p.saf, p.tox = p.tox, ntrial = ntrial,
         n.earlystop = n.earlystop, cutoff.eli = cutoff.eli,
         extrasafe = extrasafe, offset = offset),
    .bank_summarise(N, Y, dselect, stop.reason, patient.data))
}
