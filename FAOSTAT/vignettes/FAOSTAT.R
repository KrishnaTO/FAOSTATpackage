## ----setup, include=FALSE, cache=FALSE----------------------------------------
library("knitr")
opts_chunk$set(fig.path='figure/', fig.align='center', fig.show='hold',
               warning=FALSE, message=FALSE, tidy=FALSE, results='hide',
               eval=FALSE, concordance=TRUE)
options(replace.assign=TRUE,width=80)

## ----Install the FAOSTAT package - CRAN---------------------------------------
#  if(!is.element("FAOSTAT", .packages(all.available = TRUE)))
#     install.packages("FAOSTAT")
#  library(FAOSTAT)

## ----Install the FAOSTAT package - git repo-----------------------------------
#  if(!is.element("FAOSTAT", .packages(all.available = TRUE)))
#      remotes::install_gitlab(repo="paulrougieux/faostatpackage/FAOSTAT")
#  library(FAOSTAT)

## ----Vignette-----------------------------------------------------------------
#  help(package = "FAOSTAT")
#  vignette("FAOSTAT", package = "FAOSTAT")

## -----------------------------------------------------------------------------
#  url_bulk_site <- "http://fenixservices.fao.org/faostat/static/bulkdownloads"
#  url_crops <- file.path(url_bulk_site, "Production_Crops_E_All_Data_(Normalized).zip")
#  url_forestry <- file.path(url_bulk_site, "Forestry_E_All_Data_(Normalized).zip")
#  
#  
#  # Create a folder to store the data
#  data_folder <- "data_raw"
#  dir.create(data_folder)
#  
#  # Download the files
#  download_faostat_bulk(url_bulk = url_forestry, data_folder = data_folder)
#  download_faostat_bulk(url_bulk = url_crops, data_folder = data_folder)
#  
#  # Read the files and assign them to data frames
#  production_crops <- read_faostat_bulk("data_raw/Production_Crops_E_All_Data_(Normalized).zip")
#  forestry <- read_faostat_bulk("data_raw/Forestry_E_All_Data_(Normalized).zip")
#  
#  # Save the data frame in the serialized RDS format for fast reuse later.
#  saveRDS(production_crops, "data_raw/production_crops_e_all_data.rds")
#  saveRDS(forestry,"data_raw/forestry_e_all_data.rds")

## ----FAO-search, eval=FALSE---------------------------------------------------
#  ## Use the interective function to search the codes.
#  FAOsearch()
#  
#  ## Use the result of the search to download the data.
#  test = getFAO(query = .LastSearch)

## ----FAO-download, eval=FALSE-------------------------------------------------
#  ## A demonstration query
#  FAOquery.df = data.frame(varName = c("arableLand", "cerealExp", "cerealProd"),
#                           domainCode = c("RL", "TP", "QC"),
#                           itemCode = c(6621, 1944, 1717),
#                           elementCode = c(5110, 5922, 5510),
#                           stringsAsFactors = FALSE)
#  
#  ## Download the data from FAOSTAT
#  FAO.lst = with(FAOquery.df,
#      getFAOtoSYB(name = varName, domainCode = domainCode,
#                  itemCode = itemCode, elementCode = elementCode,
#                  useCHMT = TRUE, outputFormat = "wide"))
#  FAO.lst$entity[, "arableLand"] = as.numeric(FAO.lst$entity[, "arableLand"])

## ----FAO-check, eval=FALSE----------------------------------------------------
#  FAOchecked.df = FAOcheck(var = FAOquery.df$varName, year = "Year",
#                           data = FAO.lst$entity, type = "multiChina",
#                           take = "simpleCheck")

## ----WB-download, eval=FALSE--------------------------------------------------
#  ## Download World Bank data and meta-data
#  WB.lst = getWDItoSYB(indicator = c("SP.POP.TOTL", "NY.GDP.MKTP.CD"),
#                       name = c("totalPopulation", "GDPUSD"),
#                       getMetaData = TRUE, printMetaData = TRUE)

## ----fill-countrycode,  eval=FALSE--------------------------------------------
#  ## Just a demonstration
#  Demo = WB.lst$entity[, c("Country", "Year", "totalPopulation")]
#  demoResult = fillCountryCode(country = "Country", data = Demo,
#      outCode = "ISO2_WB_CODE")
#  
#  ## Countries have not been filled in.
#  unique(demoResult[is.na(demoResult$ISO2_WB_CODE), "Country"])

## ----translate, warning=TRUE,  eval=FALSE-------------------------------------
#  ## Countries which are not listed under the ISO2 international standard.
#  FAO.df = translateCountryCode(data = FAOchecked.df, from = "FAOST_CODE",
#      to = "ISO2_CODE")
#  
#  ## Countries which are not listed under the UN M49 system.
#  WB.df = translateCountryCode(data = WB.lst$entity, from = "ISO2_WB_CODE",
#      to = "UN_CODE")

## ----merge, warning=TRUE,  eval=FALSE-----------------------------------------
#  merged.df = mergeSYB(FAOchecked.df, WB.lst$entity, outCode = "FAOST_CODE")

## ----Scale to basic unit, eval=FALSE------------------------------------------
#  multipliers = data.frame(Variable = c("arableLand", "cerealExp", "cerealProd",
#                                        "totalPopulation", "GDPUSD"),
#                           Multipliers = c("thousand", NA, NA, NA, NA),
#                           stringsAsFactors = FALSE)
#  multipliers[, "Multipliers"] =
#    as.numeric(translateUnit(multipliers[, "Multipliers"]))
#  preConstr.df = scaleUnit(merged.df, multipliers)

## ----Construction, eval=FALSE-------------------------------------------------
#  con.df = data.frame(STS_ID = c("arableLandPC", "arableLandShareOfTotal",
#                                 "totalPopulationGeoGR", "totalPopulationLsGR",
#                                 "totalPopulationInd", "totalPopulationCh"),
#                      STS_ID_CONSTR1 = c(rep("arableLand", 2),
#                                         rep("totalPopulation", 4)),
#                      STS_ID_CONSTR2 = c("totalPopulation", NA, NA, NA, NA, NA),
#                      STS_ID_WEIGHT = rep("totalPopulation", 6),
#                      CONSTRUCTION_TYPE = c("share", "share", "growth", "growth",
#                                            "index", "change"),
#                      GROWTH_RATE_FREQ = c(NA, NA, 10, 10, NA, 1),
#                      GROWTH_TYPE = c(NA, NA, "geo", "ls", NA, NA),
#                      BASE_YEAR = c(NA, NA, NA, NA, 2000, NA),
#                      AGGREGATION = rep("weighted.mean", 6),
#                      THRESHOLD_PROP = rep(60, 6),
#                      stringsAsFactors = FALSE)
#  
#  postConstr.lst = with(con.df,
#                        constructSYB(data = preConstr.df,
#                                     origVar1 = STS_ID_CONSTR1,
#                                     origVar2 = STS_ID_CONSTR2,
#                                     newVarName = STS_ID,
#                                     constructType = CONSTRUCTION_TYPE,
#                                     grFreq = GROWTH_RATE_FREQ,
#                                     grType = GROWTH_TYPE,
#                                     baseYear = BASE_YEAR))

## ----aggregation, eval=FALSE--------------------------------------------------
#  ## Compute aggregates under the FAO continental region.
#  relation.df = FAOregionProfile[, c("FAOST_CODE", "UNSD_MACRO_REG")]
#  
#  Macroregion.df = Aggregation(data = postConstr.lst$data,
#                               relationDF = relation.df,
#                               aggVar = c("arableLand", "totalPopulation",
#                                          "arableLandPC"),
#                               weightVar = c(NA, NA, "totalPopulation"),
#                               aggMethod = c("sum", "sum", "weighted.mean"),
#                               applyRules = TRUE,
#                               keepUnspecified = TRUE,
#                               unspecifiedCode = "NotClassified",
#                               thresholdProp = c(rep(0.65,3)))

