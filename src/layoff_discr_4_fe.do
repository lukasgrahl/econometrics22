*Preamble
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\2022_econometrics"
log using "log\layoff_discr_4_fe.log", replace tex

use "data\layoff_discr\cps_main_prepro.dta", clear

*tab unemployement by race and month
tabulate race_cat is_layoff, row nofreq chi2

/*##########################################
Assumption check
##########################################*/

*corr matrix
correlate /// 
gender is_poc is_asian is_hisp is_native /// variables of interest
age age2 level_educ hh_income is_more1job no_child contract_type ///control variables

* check number of clusters
tabulate us_state naic_2dig
// even on naic 2 digit level there is no sufficient clusters


*VARIABLES 

* other - non included variables
global OVars "marista is_more1job new_death housing_kind pnew_death hh_weight hh_no_people dur_layoff tot_cases owns_business hsp_race birtcountr  mo_birtcountr fa_birtcoutr prob_cases zip_code imig_year"

* control variables X
global XVars age age2 level_educ contract_type" // is_vet hh_income is_uscitiz"

* variables of interest
global IVArs "race gender no_child new_casespm is_poc is_hisp is_asian is_native" // no_child telewworkable_wage"

* fixed effect varibles
// "us_state naic_id" //hh_id 

* dependent variable
// "is_layoff"


/*##########################################
Fixed Effect Model by month
############################################*/
* select month
keep if hrmonth==5

*set fixed effects
reghdfe ///
is_layoff /// dependent var
gender is_poc is_asian is_hisp is_native /// variables of interest
age age2 level_educ hh_income is_more1job no_child contract_type 		owns_business teleworkable_wage teleworkable_emp ///control variables
//// interaction terms
[fweight=hh_weight] /// weigt variable
,absorb(us_state) /// fixed effects
cluster(new_casespm new_deathpm) /// cluster


/*##########################################
Fixed effects Model across month
############################################*/
use "data\layoff_discr\cps_main_prepro.dta", clear

* excludig consecutive observation of households
sort hh_id
quietly by hh_id:  gen dup = cond(_N==1,0,_n)
keep if dup<=1

*set fixed effects reg

reghdfe ///
is_layoff /// dependent var
gender is_poc is_asian is_hisp is_native /// variables of interest
age age2 level_educ hh_income is_more1job no_child contract_type owns_business teleworkable_wage teleworkable_emp ///control variables
i.hrmonth#us_state //// interaction terms
[fweight=hh_weight] /// weigt variable
,absorb(us_state) /// fixed effects
cluster(new_casespm new_deathpm) /// cluster


/*##########################################
Var exclusion - explained
############################################*/
* no_child has large number of missig values, thus not very informative
* is_vet is not significant across any model

/*##########################################
Further ideas
############################################*/
* include avg. seasonal unemployment by state to reflect ususal economic fluction
* this would strengthen the correction for cyclical unemployment - to this point only based on exclusion of non-recent unemployment

* naic us_state clusters: can we impute clusters, as only very few are missing




