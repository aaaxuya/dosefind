# PCS follows legacy: select the dose with true mean closest to target.
# A tie selects the lowest dose (which.min). 99 = no MTD, counted as incorrect.
summarise_pcs <- function(simulation) {
  cfg <- simulation$settings
  comparisons <- trials <- truths <- list()
  index <- 0L
  for (scenario in names(simulation$results)) {
    true_mean <- as.vector(cfg$score_raw %*% cfg$scenarios[[scenario]])
    true_mtd <- which.min(abs(true_mean - cfg$target_raw))
    truths[[scenario]] <- data.frame(
      scenario = scenario, dose = seq_along(true_mean),
      true_mean_raw = true_mean,
      true_mean_normalized = true_mean / max(cfg$score_raw),
      target_raw = cfg$target_raw, is_true_mtd = seq_along(true_mean) == true_mtd
    )
    for (method in names(simulation$results[[scenario]])) {
      index <- index + 1L
      oc <- simulation$results[[scenario]][[method]]
      selected <- oc$dselect
      if (length(selected) != cfg$ntrial || anyNA(selected) ||
          any(!(selected %in% c(seq_along(true_mean), 99L)))) {
        stop("Invalid recommendations for ", scenario, " / ", method)
      }
      correct <- selected == true_mtd
      pcs <- mean(correct)
      comparisons[[index]] <- data.frame(
        scenario = scenario, method = method, true_mtd = true_mtd,
        ntrial = length(selected), n_correct = sum(correct),
        PCS_percent = 100 * pcs,
        MCSE_percent = 100 * sqrt(pcs * (1 - pcs) / length(selected)),
        no_MTD_percent = 100 * mean(selected == 99L),
        mean_total_n = mean(rowSums(oc$N))
      )
      trials[[index]] <- data.frame(
        scenario = scenario, method = method, trial = seq_along(selected),
        selected_dose = selected, true_mtd = true_mtd, correct_selection = correct,
        total_n = rowSums(oc$N), stop_reason = oc$stop.reason
      )
    }
  }
  list(comparison = do.call(rbind, comparisons), trials = do.call(rbind, trials),
       truth = do.call(rbind, unname(truths)))
}

plot_pcs <- function(comparison, file, device = c("png", "pdf")) {
  device <- match.arg(device)
  scenarios <- unique(comparison$scenario)
  ncol_panel <- min(2L, length(scenarios))
  nrow_panel <- ceiling(length(scenarios) / ncol_panel)
  if (device == "png") {
    grDevices::png(file, width = 1600 * ncol_panel, height = 1100 * nrow_panel, res = 180)
  } else {
    grDevices::pdf(file, width = 8 * ncol_panel, height = 5.5 * nrow_panel)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mfrow = c(nrow_panel, ncol_panel), mar = c(5, 5, 4, 1))
  methods <- c("RQ-CRM", "Quasi-CRM", "gBOIN")
  colors <- c("#5177A6", "#6FA58E", "#D0A25C")
  for (scenario in scenarios) {
    x <- comparison[comparison$scenario == scenario, ]
    x <- x[match(methods, x$method), ]
    if (anyNA(x$method)) stop("Missing method in scenario: ", scenario)
    positions <- graphics::barplot(
      x$PCS_percent, names.arg = methods, ylim = c(0, 110),
      col = colors, border = NA, axes = FALSE,
      ylab = "PCS (%)", main = paste0(scenario, " | True MTD = dose ", x$true_mtd[1L])
    )
    graphics::axis(2, at = seq(0, 100, 20), las = 1)
    graphics::box(bty = "l")
    graphics::text(as.vector(positions), x$PCS_percent + 3,
                   labels = sprintf("%.2f%%", x$PCS_percent), font = 2)
    graphics::mtext(paste0("repiplicate number: ", x$ntrial[1L]), side = 3, line = 0.3, cex = 0.8)
  }
  invisible(file)
}

write_pcs_outputs <- function(tables, simulation) {
  output_dir <- simulation$settings$output_dir
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (name in names(tables)) {
    utils::write.csv(tables[[name]], file.path(output_dir, paste0(name, ".csv")),
                     row.names = FALSE, fileEncoding = "UTF-8")
  }
  plot_pcs(tables$comparison, file.path(output_dir, "PCS.png"), "png")
  plot_pcs(tables$comparison, file.path(output_dir, "PCS.pdf"), "pdf")
  capture.output(simulation$session_info, file = file.path(output_dir, "sessionInfo.txt"))
  message("Saved PCS tables and figures to ", output_dir)
  invisible(tables)
}
