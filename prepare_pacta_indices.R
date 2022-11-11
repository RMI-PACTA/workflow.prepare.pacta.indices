# necessary packages -----------------------------------------------------------
# please add all dependencies to imports.R
source("./imports.R")
invisible({
  lapply(
    requirements,
    library,
    character.only = TRUE
  )
})

# paths ------------------------------------------------------------------------
transition_monitor_dir <- "/home/bound"
setwd(transition_monitor_dir)

working_dir <- file.path(transition_monitor_dir, "working_dir")

input_dir <- "/home/pacta-data/2021Q4"
output_dir <- input_dir


# options ----------------------------------------------------------------------

pacta_directories <- c(
  "00_Log_Files",
  "10_Parameter_File",
  "20_Raw_Inputs",
  "30_Processed_Inputs",
  "40_Results",
  "50_Outputs"
)

holdings_date <- "2021Q4"

# load indices data -------------------------------------------------------

ishares_indices_bonds <- readRDS(file.path(input_dir, "ishares_indices_bonds.rds"))
ishares_indices_equity <- readRDS(file.path(input_dir, "ishares_indices_equity.rds"))

ishares_indices <- bind_rows(ishares_indices_bonds, ishares_indices_equity)


# -------------------------------------------------------------------------

temporary_directory <- tempdir()

portfolio_names <- unique(ishares_indices$portfolio_name)

for (portfolio_name in portfolio_names) {

  fs::dir_delete(working_dir)
  fs::dir_create(file.path(working_dir, pacta_directories))

  portfolio <-
    ishares_indices %>%
    filter(portfolio_name == .env$portfolio_name)

  investor_name <- unique(portfolio$investor_name)

  if (length(investor_name) != 1L) {
    stop("Please ensure that each index dataset contains a single unique value for `investor_name`")
  }

  config_list <-
    list(
      default = list(
        parameters = list(
          investor_name = investor_name,
          portfolio_name = portfolio_name,
          language = "EN",
          project_code = investor_name,
          holdings_date = holdings_date
        )
      )
    )

  yaml::write_yaml(
    config_list,
    file = file.path(
      working_dir,
      "10_Parameter_File",
      paste0(portfolio_name, "_PortfolioParameters.yml")
    )
  )

  write_csv(
    portfolio,
    file.path(working_dir, "20_Raw_Inputs", paste0(portfolio_name,".csv"))
  )

  portfolio_name_ref_all <- portfolio_name

  cli::cli_alert_info("running PACTA on: {.emph {portfolio_name}}")
  source("/home/bound/web_tool_script_1.R", local = TRUE)
  source("/home/bound/web_tool_script_2.R", local = TRUE)

  emissions <- file.path(working_dir, "30_Processed_Inputs", portfolio_name, "emissions.rds")

  eq_result <- file.path(working_dir, "40_Results", portfolio_name, "Equity_results_portfolio.rds")
  bond_result <- file.path(working_dir, "40_Results", portfolio_name, "Bonds_results_portfolio.rds")

  emissions_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(emissions)))
  eq_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(eq_result)))
  bond_out <- file.path(temporary_directory, paste0(portfolio_name, "_", basename(bond_result)))

  if (file.exists(emissions)) { file.copy(emissions, emissions_out) }
  if (file.exists(eq_result)) { file.copy(eq_result, eq_out) }
  if (file.exists(bond_result)) { file.copy(bond_result, bond_out) }
}


# -------------------------------------------------------------------------

output_files <- list.files(
  temporary_directory,
  pattern = "*_portfolio[.]rds$",
  full.names = TRUE
  )

combined <-
  output_files %>%
  map_dfr(readRDS)

unlink(output_files)

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

combined %>%
  filter(!grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(file.path(output_dir, "Indices_equity_portfolio.rds"))

combined %>%
  filter(grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(file.path(output_dir, "Indices_bonds_portfolio.rds"))

# -------------------------------------------------------------------------
# output emissions data

output_files_emissions <- list.files(
  "~/Desktop/test_directory/",
  pattern = "emissions[.]rds$",
  full.names = TRUE
)

combined_emissions <- output_files_emissions %>%
  map_dfr(readRDS)

unlink(output_files_emissions)

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

combined_emissions %>%
  filter(!grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(file.path(output_dir, "Indices_equity_emissions.rds"))

combined_emissions %>%
  filter(grepl("Global Corp Bond", portfolio_name)) %>%
  saveRDS(file.path(output_dir, "Indices_bonds_emissions.rds"))
