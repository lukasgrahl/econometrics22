*Preamble
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_4_fe.log", replace tex

use "data\layoff_discr\cps_main_prepro.dta", clear

*tab unemployement by race and month
tabulate race_cat is_layoff, row nofreq chi2

/*##########################################
Assumption check
##########################################*/

*corr matrix
correlate /// 
gender is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
is_uscitiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind

* new_casespm ~ new_deathpm corr .6
* hh_income ~ level_educ corr .35
* marista ~ age corr .35
* age ~ age2 corr .98
* is_uscitiz * is_asian .38


* check number of clusters
tabulate us_state naic_2dig

/*##########################################
Fixed Effect Model by month
############################################*/
* select month
keep if hrmonth==5

reghdfe ///
is_layoff ///
gender is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
i.(is_uscitiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind) ///
[fweight=hh_weight] ///
,absorb(us_state naic_id) ///


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
is_layoff ///
gender is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
i.(hrmonth is_uscitiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind) ///
[fweight=hh_weight] ///
,absorb(us_state naic_id) ///


reghdfe ///
is_layoff ///
gender is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
i.(is_uscitiz level_educ hh_income contract_type owns_business is_more1job no_child is_vet) ///
i.(us_state#hrmonth) ///
[fweight=hh_weight] ///
,absorb(naic_id) ///


/*##########################################
Further ideas
############################################*/
* include avg. seasonal unemployment by state to reflect ususal economic fluction
* this would strengthen the correction for cyclical unemployment - to this point only based on exclusion of non-recent unemployment
* two fixed effects 'absorb(state naic)', hrmonth as categorical or	absorb(naic) i.us_state#hrmonth


