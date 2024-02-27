logger::log_threshold(Sys.getenv("LOG_LEVEL", ifelse(interactive(), "FATAL", "INFO")))
logger::log_formatter(logger::formatter_glue)

logger::log_info("main.R.")

# necessary packages -----------------------------------------------------------
# please add all dependencies to imports.R
logger::log_info("Loading necessary packages.")
suppressPackageStartupMessages({
  library("dplyr")
  library("purrr")
  library("readr")
})

logger::log_info("Loading config.")
config <-
  config::get(
    file = "config.yml",
    config = Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE
  )

pacta_financial_timestamp <- config$pacta_financial_timestamp
logger::log_debug("pacta_financial_timestamp: {pacta_financial_timestamp}.")
ishares_date <- config$ishares_date
logger::log_debug("ishares_date: {ishares_date}.")

# paths ------------------------------------------------------------------------
logger::log_info("Setting paths.")

transition_monitor_dir <- "/bound"
logger::log_info("changing directory to transition_monitor_dir: {transition_monitor_dir}.")
setwd(transition_monitor_dir)

working_dir <- file.path(transition_monitor_dir, "working_dir")
logger::log_debug("working_dir: {working_dir}.")

input_dir <- file.path("/pacta-data/", pacta_financial_timestamp)
logger::log_debug("input_dir: {input_dir}.")

output_dir <- file.path("/mnt/outputs")
logger::log_debug("output_dir: {output_dir}.")

# functions --------------------------------------------------------------------
logger::log_info("Defining functions")
add_inv_and_port_names_if_needed <- function(data,
                                             investor_name,
                                             portfolio_name) {
  if (!"portfolio_name" %in% names(data)) {
    data <- data %>%
      mutate(portfolio_name = .env$portfolio_name, .before = everything())
  }

  if (!"investor_name" %in% names(data)) {
    data <- data %>%
      mutate(investor_name = .env$investor_name, .before = everything())
  }

  data
}

# options ----------------------------------------------------------------------

pacta_directories <- c(
  "00_Log_Files",
  "10_Parameter_File",
  "20_Raw_Inputs",
  "30_Processed_Inputs",
  "40_Results",
  "50_Outputs"
)

# load indices data -------------------------------------------------------
logger::log_info("Scraping indices data")

bonds_indices_urls <- config$bonds_indices_urls
logger::log_debug("bonds_indices_urls: {bonds_indices_urls}.")

equity_indices_urls <- config$equity_indices_urls
logger::log_debug("equity_indices_urls: {equity_indices_urls}.")

logger::log_debug("Scraping iShares indices bonds data.")
ishares_indices_bonds <-
  dplyr::bind_rows(
    lapply(
      seq_along(bonds_indices_urls), function(index) {
        pacta.data.scraping::get_ishares_index_data(
          bonds_indices_urls[[index]],
          names(bonds_indices_urls)[[index]],
          ishares_date
        )
      }
    )
  ) %>%
  pacta.data.scraping::process_ishares_index_data()

logger::log_debug("Scraping iShares indices equity data.")
ishares_indices_equity <-
  dplyr::bind_rows(
    lapply(
      seq_along(equity_indices_urls), function(index) {
        pacta.data.scraping::get_ishares_index_data(
          equity_indices_urls[[index]],
          names(equity_indices_urls)[[index]],
          ishares_date
        )
      }
    )
  ) %>%
  pacta.data.scraping::process_ishares_index_data()

logger::log_debug("Combining iShares indices data.")
ishares_indices <- bind_rows(ishares_indices_bonds, ishares_indices_equity)


# -------------------------------------------------------------------------

temporary_directory <- tempdir()
logger::log_debug("temporary_directory for outputs: {temporary_directory}.")

portfolio_names <- unique(ishares_indices$portfolio_name)
logger::log_info("portfolio_names: {portfolio_names}.")

for (portfolio_name in portfolio_names) {
  logger::log_info("Processing portfolio: {portfolio_name}.")

  logger::log_debug("Creating directories for portfolio.")
  fs::dir_delete(working_dir)
  fs::dir_create(file.path(working_dir, pacta_directories))

  logger::log_trace("Filtering index data to portfolio: {portfolio_name}.")
  portfolio <-
    ishares_indices %>%
    filter(portfolio_name == .env$portfolio_name)

  investor_name <- unique(portfolio$investor_name)

  if (length(investor_name) != 1L) {
    logger::log_error("Multiple investor names found in data: {investor_name}.")
    stop("Please ensure that each index dataset contains a single unique value for `investor_name`")
  }

  logger::log_debug("Defining portfolio parameters.")
  config_list <-
    list(
      default = list(
        parameters = list(
          investor_name = investor_name,
          portfolio_name = portfolio_name,
          language = "EN",
          project_code = investor_name,
          holdings_date = pacta_financial_timestamp
        )
      )
    )

  parameters_file <- file.path(
    working_dir,
    "10_Parameter_File",
    paste0(portfolio_name, "_PortfolioParameters.yml")
  )
  logger::log_debug("Writing portfolio parameters to file: \"{parameters_file}\".")
  yaml::write_yaml(
    config_list,
    file = parameters_file
  )

  portfolio_file <- file.path(
    working_dir,
    "20_Raw_Inputs",
    paste0(portfolio_name, ".csv")
  )
  logger::log_debug("Writing portfolio data to file: \"{portfolio_file}\".")
  write_csv(
    portfolio,
    portfolio_file
  )

  logger::log_info("running PACTA on: {portfolio_name}.")
  system(paste0("Rscript --vanilla /bound/web_tool_script_1.R ", "'", portfolio_name, "'"))
  system(paste0("Rscript --vanilla /bound/web_tool_script_2.R ", "'", portfolio_name, "'"))
  logger::log_info("finished running PACTA on: {portfolio_name}.")


  audit_file <- file.path(working_dir, "30_Processed_Inputs", portfolio_name, "audit_file.rds")
  emissions <- file.path(working_dir, "30_Processed_Inputs", portfolio_name, "emissions.rds")

  eq_result <- file.path(working_dir, "40_Results", portfolio_name, "Equity_results_portfolio.rds")
  bond_result <- file.path(working_dir, "40_Results", portfolio_name, "Bonds_results_portfolio.rds")

  audit_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(audit_file)))
  emissions_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(emissions)))
  eq_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(eq_result)))
  bond_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(bond_result)))

  if (file.exists(audit_file)) {
    logger::log_debug("Reading audit file: {audit_file}.")
    audit_ind <- readRDS(audit_file)
    audit_ind <- add_inv_and_port_names_if_needed(audit_ind, investor_name, portfolio_name)
    logger::log_debug("Rewriting audit file results to temporary_directory: {audit_out}.")
    saveRDS(audit_ind, audit_out)
  } else {
    logger::log_warn("Audit file not found for portfolio {portfolio_name}: {audit_file}.")
    warning("Audit file not found.")
  }

  if (file.exists(emissions)) {
    logger::log_debug("Reading emissions file: {emissions}.")
    emissions_ind <- readRDS(emissions)
    emissions_ind <- add_inv_and_port_names_if_needed(emissions_ind, investor_name, portfolio_name)
    logger::log_debug("Rewriting emissions file results to temporary_directory: {emissions_out}.")
    saveRDS(emissions_ind, emissions_out)
  } else {
    logger::log_warn("Emissions file not found for portfolio {portfolio_name}: {emissions}.")
    warning("Emissions file not found.")
  }

  if (file.exists(eq_result)) {
    logger::log_debug("Reading equity results file: {eq_result}.")
    eq_result_ind <- readRDS(eq_result)
    eq_result_ind <- add_inv_and_port_names_if_needed(eq_result_ind, investor_name, portfolio_name)
    logger::log_debug("Rewriting equity results file to temporary_directory: {eq_out}.")
    saveRDS(eq_result_ind, eq_out)
  } else {
    logger::log_warn("Equity results file not found for portfolio {portfolio_name}: {eq_result}.")
    warning("Equity results file not found.")
  }

  if (file.exists(bond_result)) {
    logger::log_debug("Reading bond results file: {bond_result}.")
    bond_result_ind <- readRDS(bond_result)
    bond_result_ind <- add_inv_and_port_names_if_needed(bond_result_ind, investor_name, portfolio_name)
    logger::log_debug("Rewriting bond results file to temporary_directory: {bond_out}.")
    saveRDS(bond_result_ind, bond_out)
  } else {
    logger::log_warn("Bond results file not found for portfolio {portfolio_name}: {bond_result}.")
    warning("Bond results file not found.")
  }

}


# -------------------------------------------------------------------------

output_files <- list.files(
  temporary_directory,
  pattern = "*_portfolio[.]rds$",
  full.names = TRUE
)

logger::log_info("Combining results files.")
combined <-
  output_files %>%
  map_dfr(readRDS)

logger::log_debug("Unlinking temporary results files.")
unlink(output_files)

logger::log_debug("Cleaning portfolio names in combined results.")
combined <-
  combined %>%
  mutate(portfolio_name = case_when(
    grepl("S&P", portfolio_name) ~ "iShares Core S&P 500 ETF",
    grepl("MSCI World", portfolio_name) ~ "iShares MSCI World ETF",
    grepl("MSCI Emerging Markets", portfolio_name) ~ "iShares MSCI Emerging Markets ETF",
    grepl("Global Corp Bond", portfolio_name) ~ "iShares Global Corp Bond UCITS ETF",
    grepl("MSCI ACWI", portfolio_name) ~ "iShares MSCI ACWI ETF",
    TRUE ~ portfolio_name
  ))


equity_results_path <- file.path(output_dir, "Indices_equity_results_portfolio.rds")
logger::log_info("Saving combined equity results to: {equity_results_path}.")
combined %>%
  filter(!grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(equity_results_path)

bonds_results_path <- file.path(output_dir, "Indices_bonds_results_portfolio.rds")
logger::log_info("Saving combined bond results to: {bonds_results_path}.")
combined %>%
  filter(grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(bonds_results_path)

# -------------------------------------------------------------------------
# output emissions data

output_files_emissions <- list.files(
  temporary_directory,
  pattern = "emissions[.]rds$",
  full.names = TRUE
)

logger::log_info("Combining emissions files.")
combined_emissions <- output_files_emissions %>%
  map_dfr(readRDS)

logger::log_debug("Unlinking temporary emissions files.")
unlink(output_files_emissions)

logger::log_debug("Cleaning portfolio names in combined emissions.")
combined_emissions <-
  combined_emissions %>%
  mutate(portfolio_name = case_when(
    grepl("S&P", portfolio_name) ~ "iShares Core S&P 500 ETF",
    grepl("MSCI World", portfolio_name) ~ "iShares MSCI World ETF",
    grepl("MSCI Emerging Markets", portfolio_name) ~ "iShares MSCI Emerging Markets ETF",
    grepl("Global Corp Bond", portfolio_name) ~ "iShares Global Corp Bond UCITS ETF",
    grepl("MSCI ACWI", portfolio_name) ~ "iShares MSCI ACWI ETF",
    TRUE ~ portfolio_name
  ))

equity_emissions_path <- file.path(output_dir, "Indices_equity_emissions.rds")
logger::log_info("Saving combined equity emissions to: {equity_emissions_path}.")
combined_emissions %>%
  filter(!grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(equity_emissions_path)

bonds_emissions_path <- file.path(output_dir, "Indices_bonds_emissions.rds")
logger::log_info("Saving combined bond emissions to: {bonds_emissions_path}.")
combined_emissions %>%
  filter(grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(bonds_emissions_path)

# -------------------------------------------------------------------------
# output audit file

output_files_audit <- list.files(
  temporary_directory,
  pattern = "audit_file[.]rds$",
  full.names = TRUE
)

logger::log_info("Combining audit files.")
combined_audit <- output_files_audit %>%
  map_dfr(readRDS)

logger::log_debug("Unlinking temporary audit files.")
unlink(output_files_audit)

logger::log_debug("Cleaning portfolio names in combined audit.")
combined_audit <-
  combined_audit %>%
  mutate(portfolio_name = case_when(
    grepl("S&P", portfolio_name) ~ "iShares Core S&P 500 ETF",
    grepl("MSCI World", portfolio_name) ~ "iShares MSCI World ETF",
    grepl("MSCI Emerging Markets", portfolio_name) ~ "iShares MSCI Emerging Markets ETF",
    grepl("Global Corp Bond", portfolio_name) ~ "iShares Global Corp Bond UCITS ETF",
    grepl("MSCI ACWI", portfolio_name) ~ "iShares MSCI ACWI ETF",
    TRUE ~ portfolio_name
  ))

equity_audit_path <- file.path(output_dir, "Indices_equity_audit.rds")
logger::log_info("Saving combined equity audit to: {equity_audit_path}.")
combined_audit %>%
  filter(!grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(equity_audit_path)

bonds_audit_path <- file.path(output_dir, "Indices_bonds_audit.rds")
logger::log_info("Saving combined bond audit to: {bonds_audit_path}.")
combined_audit %>%
  filter(grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(bonds_audit_path)

logger::log_info("Finished main.R.")
