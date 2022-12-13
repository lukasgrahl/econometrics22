*Preamble
clear mata
capture log close
clear

cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_4_fe.log", replace tex
use "data\layoff_discr\cps_main_prepro.dta", clear

*tab unemployement by race and month
tabulate race_cat is_layoff, row nofreq chi2

* how to export that table into a nice format ??

/*##########################################
Assumption check
##########################################*/

*corr matrix
correlate /// 
is_female is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
is_citiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind

* new_casespm ~ new_deathpm corr .6
* hh_income ~ level_educ corr .35
* marista ~ age corr .35
* age ~ age2 corr .98
* is_citiz * is_asian .38


/*##########################################
Setting variables and data
############################################*/
* global vars
global TimeCat "hrmonth"

global ControlCatEduc "hh_income level_educ"
global ControlCatFam "marista" // no_child  housing_kind is_citiz
global ConntrolCatJob "owns_business contract_type is_more1job"
global ControlContin "age age2"
global ControlCovid "new_deathpm new_casespm"
global ControlProf "teleworkable_wage teleworkable_emp"

global InterestVars "is_female is_poc is_asian is_hisp is_native"
global DependVar "is_layoff"
global Cluster "naic_id"

* excludig consecutive observation of households
sort hh_id
quietly by hh_id:  gen dup = cond(_N==1,0,_n)
keep if dup<=1

/*##########################################
To Do
############################################*/

// *Run the Hausman Test
// hausman FE RE 

// *Run Heteroskedacity test
// white or breusch pagan

// * robust standard erros and het white test


/*##########################################
Fixed effect models
############################################*/

* Hausman test, Wald test
xtset us_state
xtreg $DependVar $InterestVars, fe
eststo FE
*test for heteroskedacity
xttest3 // We can reject H0: sigma(i)^2 varies, thus there is herteroskedacity

xtreg $DependVar $InterestVars, re
eststo RE

* Hausman test: H0 Difference in coefficients not systematic
hausman FE RE // we can reject the H0, differences are systematic thus FE

* Heteroskedacity
* As heteroskedacity exists we are clustering our regressions by naic_id, to correct standar errors. We do not use vce(robust), as it assumes observations to be independent. An assumption that in a model of common intercepts by groups (stat and profession) is unlikely to hold.


*1: BASELINE MODEL
* State fixed effects, industry not included
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
[aweight=hh_weight] ///
,absorb(us_state)

eststo M1
quietly estadd local FE_S "Yes", replace
quietly estadd local FE_ST "No", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace

*Heteroskedacity testing

*2: MODEL
* State and industry fixed effects
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
[aweight=hh_weight] ///
,absorb(us_state naic_id) ///
vce(cluster $Cluster)

eststo M2
quietly estadd local FE_S "Yes", replace
quietly estadd local FE_ST "No", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace

*3: MODEL
* adding age, education and income, as well as time
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin i.$ControlCatEduc ///
i.$TimeCat ///
[aweight=hh_weight] ///
,absorb(us_state naic_id) ///
vce(cluster $Cluster)

eststo M3
quietly estadd local FE_S "Yes", replace
quietly estadd local FE_ST "No", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace

*4: Model
* adding control variables of family status and job related information
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin i.($ControlCatEduc $ConntrolCatJob $ControlCatFam) ///
i.$TimeCat ///
[aweight=hh_weight] ///
,absorb(us_state naic_id) ///
vce(cluster $Cluster)

eststo M4
quietly estadd local FE_S "Yes", replace
quietly estadd local FE_ST "No", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace


*5: MODEL
* adding covid cases and time dimension
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.($ControlCatEduc $ControlCatFam $ConntrolCatJob) ///
$ControlCovid ///
i.$TimeCat ///
[aweight=hh_weight] ///
,absorb(us_state naic_id) ///
vce(cluster $Cluster)

eststo M5
quietly estadd local FE_S "Yes", replace
quietly estadd local FE_ST "No", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace

*6: Model
* we believe there is a fixed effect of state&time, implying that something (policy) 
* varies over time, and that this needs to be accounted for
* adding controls
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.($ControlCatEduc $ControlCatFam $ConntrolCatJob) ///
[aweight=hh_weight] ///
,absorb(us_state#hrmonth naic_id) ///
vce(cluster $Cluster)

eststo M6
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace


*7: Model
* we believe there is some significance to time&profession effects, wherefore 
* we add these alongside the state&time fixed effect
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.($ControlCatEduc $ControlCatFam $ConntrolCatJob) ///
/// $ControlProf $ControlCovid
[aweight=hh_weight] ///
,absorb(us_state#hrmonth naic_id#hrmonth) ///
vce(cluster $Cluster)

eststo M7_0
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "No", replace
quietly estadd local FE_IT "Yes", replace
quietly estadd local WEIG "Yes", replace

estadd ysumm, replace

/*##########################################
FE for County instead of state
############################################*/
preserve
drop if county_code==.

* get this to table - different percentages
tabulate race_cat is_layoff, row nofreq chi2

// quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.($ControlCatEduc $ControlCatFam $ConntrolCatJob) ///
,absorb(county_code#hrmonth naic_id#hrmonth) ///
vce(cluster $Cluster)

eststo M7_1
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "No", replace
quietly estadd local FE_IT "Yes", replace
quietly estadd local WEIG "No", replace

estadd ysumm, replace

restore

* robert meeting
/*
- show what weights in table with footnoe
- run herteroskedacity on baseline reg
*/


/*##########################################
Tables
############################################*/
// * Prepare estimates for -estout-
// 	estfe . model*, labels(turn "Turn FE" turn#trunk "Turn-Trunk FE")
// 	return list
//
// * Run estout/esttab
// 	esttab . model* , indicate("Length Controls=length" `r(indicate_fe)')
//		
// * Return stored estimates to their previous state
// 	estfe . model*, restore

// #delimit ;
// esttab M1 M2 M3 M4 M5 M6 M7_0 using "tables\Regs_table.csv",
// 	label se star(* 0.10 ** 0.05 *** 0.01)
// 	s(feS feST feP  clPT clST N ymean,
// 	label("State FE" "State Month FE" "Industry FE" "Industry Month FE"
// 	"Analytical Weights" "Observations" "Mean of Dep. Variable"))
// 	keep($InterestVars "hh_income");
// #delimit cr







