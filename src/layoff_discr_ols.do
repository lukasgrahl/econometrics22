*Preamble
*Loading data for 200710 - 200905 from https://data.nber.org/cps-basic2/dta/
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\2022_econometrics\data\layoff_discr"
// log using "log\layoff_discr_load.log", replace tex

use "cps_main_prepro.dta", clear

/*##########################################
Set Month*/
keep if hrmonth==4
/*############################################*/

* other - non included variables
global OVars "marista is_more1job new_death housing_kind pnew_death hh_weight 	hh_no_people dur_layoff tot_cases owns_business hsp_race birtcountr  mo_birtcountr fa_birtcoutr prob_cases zip_code imig_year"

* control variables X
global CVars "age age2 level_educ contract_type is_vet hh_income is_uscitiz" 

* main variables
global MVars "race gender no_child new_casespm no_child" //telewworkable_wage"

* fixed effect varibles
global FVars "us_state naic_id is_uscitiz" //hh_id 

* dependent variable
global YVar "is_layoff"

// br $YVar $MVars $CVars

/*##########################################
OLS Regression
############################################*/

reg $YVar $MVars $CVars, robust
predict uhat, resid
predict yhat
generate uhat2 = uhat^2
// reg uhat2 $MVars $CVars

* ?? Breush-Pagan or white test - heterosckedacity
// sktest uhat // Jacques-Bera Test 
// swilk uhat // Shapiro-Wilk Test 

* RESET Test ?? - TD4

* ?? Testing for interaction - TD4

* Compare nested models by AIC

