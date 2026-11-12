*==============================================================================
* Wage analysis: individual characteristics, education and employment factors
* Data    : nlsw88 (NLSW 1988 extract, Stata Press)
* Author  : Koome Laititi
* Purpose : Reproduces the descriptive statistics and regression models (1-11
*           and the combined model) reported in docs/Wage_Analysis_Brief.pdf
* Run from: the repository root (e.g. cd "path/to/wage-analysis-nlsw88")
* Note    : Stata 17 was used for the original analysis.
*==============================================================================

clear all
set more off
capture mkdir logs
capture mkdir results
log using "logs/wage_analysis.log", replace text

*------------------------------------------------------------------------------
* 1. Load data
*------------------------------------------------------------------------------
sysuse nlsw88, clear          // alternative: use "data/nlsw88.dta", clear
describe                      // Table 1: 2,246 observations, 17 variables

*------------------------------------------------------------------------------
* 2. Dependent variable: hourly wage
*------------------------------------------------------------------------------
summarize wage, detail        // Table 2
histogram wage, normal        // Figure 1
graph export "figures/wage_histogram_stata.png", replace width(1200)

* Log transformation (skewness = 3.10 and kurtosis = 15.85 in levels)
generate lnwage = ln(wage)
label variable lnwage "Log hourly wage"

*------------------------------------------------------------------------------
* 3. Single-variable regressions (Models 1-11), robust standard errors
*------------------------------------------------------------------------------
reg lnwage i.union,     vce(robust)   // Model 1: union membership
reg lnwage grade,       vce(robust)   // Model 2: years of schooling
reg lnwage i.collgrad,  vce(robust)   // Model 3: college graduation
reg lnwage age,         vce(robust)   // Model 4: age
reg lnwage i.race,      vce(robust)   // Model 5: race (reference: White)
reg lnwage i.married,   vce(robust)   // Model 6: marital status
reg lnwage i.c_city,    vce(robust)   // Model 7: central city residence
reg lnwage i.industry,  vce(robust)   // Model 8: industry
reg lnwage hours,       vce(robust)   // Model 9: usual hours worked
reg lnwage ttl_exp,     vce(robust)   // Model 10: total work experience
reg lnwage tenure,      vce(robust)   // Model 11: job tenure

* Percentage change for a log-linear coefficient: 100 * (exp(b) - 1)
* Example (Model 1): union premium
quietly reg lnwage i.union, vce(robust)
display "Union premium (%): " %5.2f 100*(exp(_b[1.union]) - 1)   // 25.22

*------------------------------------------------------------------------------
* 4. Combined model (all explanatory variables together)
*------------------------------------------------------------------------------
reg lnwage age i.race i.married grade i.collgrad i.c_city ///
    i.industry i.union hours ttl_exp tenure, vce(robust)
* Expected: N = 1,852; R-squared = 0.4227; F(22, 1829) = 68.65

* Percentage changes for the continuous variables in the combined model
foreach v in age grade hours ttl_exp tenure {
    display "`v' (%): " %6.2f 100*(exp(_b[`v']) - 1)
}

*------------------------------------------------------------------------------
* 5. Optional diagnostics (not reported in the brief)
*------------------------------------------------------------------------------
* Multicollinearity between years of schooling and college graduation
quietly reg lnwage age i.race i.married grade i.collgrad i.c_city ///
    i.industry i.union hours ttl_exp tenure
estat vif

* Joint test of the two education measures in the combined model
quietly reg lnwage age i.race i.married grade i.collgrad i.c_city ///
    i.industry i.union hours ttl_exp tenure, vce(robust)
testparm grade i.collgrad

log close
