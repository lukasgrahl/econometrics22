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
estpost correlate /// 
is_female is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
is_citiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind

* new_casespm ~ new_deathpm corr .6
* hh_income ~ level_educ corr .35
* marista ~ age corr .35
* age ~ age2 corr .98
* is_citiz * is_asian .38


/*##########################################
Fixed effects Model across month
############################################*/
* global vars
global ControlCategor "is_citiz level_educ hh_income "
// contract_type owns_business is_more1job no_child marista housing_kind"
global ControlContin "age age2"

global InterestVars "is_female is_poc is_asian is_hisp is_native"

global DependVar "is_layoff"

use "data\layoff_discr\cps_main_prepro.dta", clear

* excludig consecutive observation of households
sort hh_id
quietly by hh_id:  gen dup = cond(_N==1,0,_n)
keep if dup<=1


* fourth best
quietly ///
reghdfe ///
$DependVar /// dependent variable
$InterestVars /// varibels of interest
$ControlContin new_deathpm new_casespm /// control continous
i.($ControlCategor) /// control categorical
,absorb(us_state naic_id) ///

eststo M4
quietly estadd local feS "Yes", replace
quietly estadd local feST "No", replace
quietly estadd local feP "Yes", replace
quietly estadd local clPT "No", replace
quietly estadd local clST "No", replace
estadd ysumm, replace


* third best
quietly ///
reghdfe ///
$DependVar /// dependent variable
$InterestVars /// varibels of interest
$ControlContin new_deathpm new_casespm /// control continous
i.($ControlCategor) /// control categorical
,absorb(us_state naic_id) ///
cluster(hrmonth#naic_id)

eststo M3
quietly estadd local feS "Yes", replace
quietly estadd local feST "No", replace
quietly estadd local feP "Yes", replace
quietly estadd local clPT "Yes", replace
quietly estadd local clST "No", replace
estadd ysumm, replace


* second best
quietly ///
reghdfe ///
$DependVar /// dependent variable
$InterestVars /// varibels of interest
$ControlContin new_deathpm new_casespm /// control continous
i.($ControlCategor) /// control categorical
,absorb(us_state#hrmonth naic_id) ///
cluster(hrmonth#naic_id)

eststo M2
quietly estadd local feS "No", replace
quietly estadd local feST "Yes", replace
quietly estadd local feP "Yes", replace
quietly estadd local clPT "Yes", replace
quietly estadd local clST "No", replace
estadd ysumm, replace


* best option
* There is variation across month and state as well as job, this variation causes herteroskedacity, which we account for by clustering

quietly ///
reghdfe ///
$DependVar /// dependent variable
$InterestVars /// varibels of interest
$ControlContin new_deathpm new_casespm /// control continous
i.($ControlCategor) /// control categorical
,absorb(us_state#hrmonth naic_id) ///
cluster(hrmonth#naic_id us_state#hrmonth)

eststo M1
quietly estadd local feS "No", replace
quietly estadd local feST "Yes", replace
quietly estadd local feP "Yes", replace
quietly estadd local clPT "Yes", replace
quietly estadd local clST "Yes", replace
estadd ysumm, replace

* run M1 on county level

/*##########################################
FE for County instead of state
############################################*/

preserve
drop if county_code==.

* get this to table - different percentages
tabulate race_cat is_layoff, row nofreq chi2

quietly ///
reghdfe ///
$DependVar /// dependent variable
$InterestVars /// varibels of interest
$ControlContin new_deathpm new_casespm /// control continous
i.($ControlCategor) /// control categorical
,absorb(county_code#hrmonth naic_id) ///
cluster(hrmonth#naic_id county_code#hrmonth)

eststo M1_1
quietly estadd local feS "No", replace
quietly estadd local feST "Yes", replace
quietly estadd local feP "Yes", replace
quietly estadd local clPT "Yes", replace
quietly estadd local clST "Yes", replace
estadd ysumm, replace

restore

/*##########################################
FE by state
############################################*/

/*
No observations for the following sates
AS, FSM, GU, MP, NYC, PR, PW, RMI, VI
*/


local USStates `" "AK" "AL" "AR" "AZ" "CA" "CO" "CT" "DC" "DE" "FL" "GA" "HI" "IA" "ID" "IL" "IN" "KS" "KY" "LA" "MA" "MD" "ME" "MI" "MN" "MO" "MS" "MT" "NC" "ND" "NE" "NH" "NJ" "NM" "NV" "NY" "OH" "OK" "OR" "PA" "RI" "SC" "SD" "TN" "TX" "UT" "VA" "VT" "WA" "WI" "WV" "WY" "'
local Enum 1
foreach x of local USStates{
	display "`x'"
	preserve
	keep if us_state_str=="`x'"
	
	quietly ///
	reghdfe ///
	$DependVar /// dependent variable
	$InterestVars /// varibels of interest
	$ControlContin new_deathpm new_casespm /// control continous
	i.($ControlCategor) /// control categorical
	,absorb(naic_id) ///
	
	* add table specifications
	eststo `x'
	quietly estadd local State `x', replace
	
	restore
	local Enum = `Enum' + 1
}


// * robert meeting
// reghdfe ///
// is_layoff ///
// i.gender is_poc is_asian is_hisp is_native ///
// age age2 ///
// i.(is_citiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind) ///
// ,absorb(us_state naic_id) ///
// cluster(hrmonth#naic_id us_state#hrmonth)

* explain why two clusters and shortcomings
* state#month
* cluster on zip code level
* discuss why note probit


/*##########################################
Tables
############################################*/


#delimit ;
esttab M4 M3 M2 M1 M1_1, //using "tables\Regs_table.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(feS feST feP  clPT clST N ymean,
	label("State FE" "State Month FE" "Profession FE" "Cluster Profession Month" "Cluster State Month" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr


#delimit ;
esttab AK AL AR AZ CA IA ID IL IN, // using "tables\State_table1.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr

#delimit ;
esttab MS MT NC ND NE NH NJ NM NV, //using "tables\State_table2.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr

#delimit ;
esttab KS KY LA MA MD ME MI MN MO, //using "tables\State_table3.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr

#delimit ;
esttab NY OH OK OR PA RI SC SD TN, //using "tables\State_table4.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr

#delimit ;
esttab TX UT VA VT WA WI WV WY, //using "tables\State_table5.rtf",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep(is_female is_poc is_asian);
#delimit cr




