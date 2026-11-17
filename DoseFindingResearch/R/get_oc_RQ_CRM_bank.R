# Standalone: source this file directly; all helpers are local to the function.
# 使用 bank 的 Quasi-CRM / Robust-Quasi-CRM。
# 改写依据：UnifiedDoseFinding 0.1.10 get_oc_RQ_CRM（GPL-2）；
# 原包作者：Chia-Wei Hsu、Haitao Pan、Rongji Mu。
# 单 skeleton 为 Quasi-CRM，多 skeleton 为 Robust-Quasi-CRM。
# score、target 使用原始评分尺度，函数内部除以 max(score)。
# 不再接受 ptox、seed；患者毒性完全来自 bank，不调用随机数生成函数。

get_oc_RQ_CRM_bank <- function(
    bank, skeletons, target, score, cohortsize = 3L,
    ncohort = floor(dim(bank)[1L] / cohortsize), n.earlystop = 100,
    start.dose = 1L, mselection = 1L, cutoff.eli = 0.90,
    ntrial = dim(bank)[3L], keep.patient.data = FALSE) {
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
                         start.dose, n.earlystop, cutoff.eli, keep.patient.data)
  .bank_probability(target / max(score), "target / max(score)")
  if (is.numeric(skeletons) && is.null(dim(skeletons))) {
    skeletons <- matrix(skeletons, nrow = 1L)
  }
  if (!is.matrix(skeletons) || !is.numeric(skeletons) || nrow(skeletons) < 1L ||
      ncol(skeletons) != dims[2L] || any(!is.finite(skeletons)) ||
      any(skeletons <= 0 | skeletons >= 1)) {
    stop("skeletons must have one column per dose and values strictly between 0 and 1.",
         call. = FALSE)
  }
  if (any(apply(skeletons, 1L, function(p) any(diff(p) <= 0)))) {
    stop("Each skeleton must be strictly increasing across doses.", call. = FALSE)
  }
  if (!is.numeric(mselection) || length(mselection) != 1L ||
      is.na(mselection) || !(mselection %in% c(1, 2))) {
    stop("mselection must be 1 (model selection) or 2 (model averaging).", call. = FALSE)
  }

  ndose <- dims[2L]
  nskel <- nrow(skeletons)
  target1 <- target / max(score)
  score1 <- score / max(score)
  npts <- ncohort * cohortsize

  # 与原包相同的幂模型和 alpha ~ N(0, 2) 先验核。
  posterior <- function(alpha, p, y, n) {
    likelihood <- rep(1, length(alpha))
    for (j in seq_along(p)) {
      pj <- p[j]^exp(alpha)
      likelihood <- likelihood * pj^y[j] * (1 - pj)^(n[j] - y[j])
    }
    likelihood * exp(-0.5 * alpha^2 / 2)
  }
  posttoxf <- function(alpha, p, y, n, j) {
    p[j]^exp(alpha) * posterior(alpha, p, y, n)
  }
  fit_model <- function(n, y) {
    marginal <- vapply(seq_len(nskel), function(k) {
      stats::integrate(posterior, -Inf, Inf, p = skeletons[k, ], y = y, n = n)$value
    }, numeric(1L))
    if (any(!is.finite(marginal)) || any(marginal <= 0)) {
      stop("CRM marginal likelihood is not positive and finite.", call. = FALSE)
    }
    postprob <- marginal / sum(marginal) # 各 skeleton 的先验概率相等。
    models <- if (mselection == 1L) which.max(postprob) else seq_len(nskel)
    weights <- if (mselection == 1L) 1 else postprob
    p.overtox <- 0
    ptox.hat <- numeric(ndose)
    for (index in seq_along(models)) {
      k <- models[index]
      p <- skeletons[k, ]
      over <- stats::integrate(
        posterior, -Inf, log(log(target1) / log(p[1L])), p = p, y = y, n = n
      )$value / marginal[k]
      p.overtox <- p.overtox + weights[index] * over
      for (j in seq_len(ndose)) {
        estimate <- stats::integrate(
          posttoxf, -Inf, Inf, p = p, y = y, n = n, j = j
        )$value / marginal[k]
        ptox.hat[j] <- ptox.hat[j] + weights[index] * estimate
      }
    }
    list(dose.best = which.min(abs(ptox.hat - target1)), p.overtox = p.overtox)
  }

  N <- Y <- matrix(0, nrow = ntrial, ncol = ndose)
  dselect <- rep.int(99L, ntrial)
  stop.reason <- rep.int("max_sample", ntrial)
  patient.data <- if (keep.patient.data) vector("list", ntrial) else NULL

  for (trial in seq_len(ntrial)) {
    n <- y <- numeric(ndose)
    dose.curr <- start.dose
    doses <- grades <- rep.int(NA_integer_, npts)
    for (cohort in seq_len(ncohort)) {
      # patient 是本试验中的入组编号，不是当前剂量下的累计人数。
      patients <- (cohort - 1L) * cohortsize + seq_len(cohortsize)
      observed <- bank[patients, dose.curr, trial]
      doses[patients] <- dose.curr
      grades[patients] <- observed
      for (grade in observed) y[dose.curr] <- y[dose.curr] + score1[grade + 1L]
      n[dose.curr] <- n[dose.curr] + cohortsize

      # 即使达到人数提前停止阈值，也先用最新数据评估毒性和最终推荐剂量。
      fit <- fit_model(n, y)
      if (fit$p.overtox > cutoff.eli) {
        stop.reason[trial] <- "overtoxicity"
        break
      }
      dselect[trial] <- fit$dose.best
      if (n[dose.curr] >= n.earlystop) {
        stop.reason[trial] <- "n.earlystop"
        break
      }
      dose.curr <- dose.curr + sign(fit$dose.best - dose.curr)
    }
    if (stop.reason[trial] == "overtoxicity") dselect[trial] <- 99L
    N[trial, ] <- n
    Y[trial, ] <- y
    if (keep.patient.data) {
      patient.data[[trial]] <- .bank_patient_data(trial, doses, grades, cohortsize, score1)
    }
  }
  c(list(method = if (nskel == 1L) "Quasi-CRM" else "Robust-Quasi-CRM",
         target = target, score = score, skeletons = skeletons,
         ncohort = ncohort, cohortsize = cohortsize, start.dose = start.dose,
         ntrial = ntrial, mselection = mselection,
         n.earlystop = n.earlystop, cutoff.eli = cutoff.eli),
    .bank_summarise(N, Y, dselect, stop.reason, patient.data))
}
