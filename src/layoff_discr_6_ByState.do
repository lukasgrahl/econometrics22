*Preamble
clear mata
capture log close
clear

cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_6_ByState.log", replace tex
use "data\layoff_discr\cps_main_prepro.dta", clear

/*##########################################
Setting variables and data
############################################*/
* global vars
global ControlCategor "hrmonth is_citiz level_educ hh_income "
// contract_type owns_business is_more1job no_child marista housing_kind"

global ControlContin "age age2"
global InterestVars "is_female is_poc is_asian is_hisp is_native"
global DependVar "is_layoff"
global PThresh 0.1

* excludig consecutive observation of households
sort hh_id
quietly by hh_id:  gen dup = cond(_N==1,0,_n)
keep if dup<=1

*exclude all observation without county code
// drop if county_code==.

/*##########################################
FE by state Profession FE
############################################*/

/*
No observations for the following sates
AS, FSM, GU, MP, NYC, PR, PW, RMI, VI
*/

tempname results
postfile `results' ///
state coef_female coef_poc coef_asian coef_native coef_hisp p_female p_poc p_asian p_native p_hisp ///
using "data\cps_bystate_prof_fe.dta", replace

local USStates `" "AK" "AL" "AR" "AZ" "CA" "CO" "CT" "DC" "DE" "FL" "GA" "HI" "IA" "ID" "IL" "IN" "KS" "KY" "LA" "MA" "MD" "ME" "MI" "MN" "MO" "MS" "MT" "NC" "ND" "NE" "NH" "NJ" "NM" "NV" "NY" "OH" "OK" "OR" "PA" "RI" "SC" "SD" "TN" "TX" "UT" "VA" "VT" "WA" "WI" "WV" "WY" "'
local Enum 1
foreach x of local USStates{
	display "`x'"
	
	preserve
	quietly keep if us_state_str=="`x'"
	
	* fe regression 
	quietly ///
	reghdfe ///
	$DependVar /// dependent variable
	$InterestVars /// varibels of interest
	$ControlContin new_deathpm new_casespm /// control continous
	i.($ControlCategor) /// control categorical
	[pweight=hh_weight_perc] ///
	,absorb(naic_id) ///
	
	* add table specifications
	eststo `x'
	quietly estadd local State `x', replace
	
	*store coefficients
	local t_f = _b[is_female]/_se[is_female]
	local t_p = _b[is_poc]/_se[is_poc]
	local t_a = _b[is_asian]/_se[is_asian]
	local t_n = _b[is_native]/_se[is_native]
	local t_h = _b[is_hisp]/_se[is_hisp]

	* get p values
	local p_f = 2*ttail(e(df_r),abs(`t_f'))
	local p_p = 2*ttail(e(df_r),abs(`t_p'))
	local p_a = 2*ttail(e(df_r),abs(`t_a'))
	local p_n = 2*ttail(e(df_r),abs(`t_n'))
	local p_h = 2*ttail(e(df_r),abs(`t_h'))
	
	post `results' ///
	(`Enum') ///
	(_b[is_female]) (_b[is_poc]) (_b[is_asian]) (_b[is_native]) (_b[is_hisp]) /// 
	(`p_f') (`p_p') (`p_a') (`p_n') (`p_h')
	
	* restore and re-initiate loop
	restore
	local Enum = `Enum' + 1
}
postclose `results'


/*##########################################
Analyse results
############################################*/

use "data\cps_bystate_prof_fe.dta", clear

* label state data
label define usstatestr 1 "AK" 2 "AL" 3 "AR" 4 "AZ" 5 "CA" 6 "CO" 7 "CT" 8 "DC" 9 "DE" 10 "FL" 11 "GA" 12 "HI" 13 "IA" 14 "ID" 15 "IL" 16 "IN" 17 "KS" 18 "KY" 19 "LA" 20 "MA" 21 "MD" 22 "ME" 23 "MI" 24 "MN" 25 "MO" 26 "MS" 27 "MT" 28 "NC" 29 "ND" 30 "NE" 31 "NH" 32 "NJ" 33 "NM" 34 "NV" 35 "NY" 26 "OH" 27 "OK" 28 "OR" 39 "PA" 40 "RI" 41 "SC" 42 "SD" 43 "TN" 44 "TX" 45 "UT" 46 "VA" 47 "VT" 48 "WA" 49 "WI" 50 "WV" 51"WY"
label value state usstatestr

* get significance
gen coef_female_sig= coef_female * (p_female <= $PThresh)
gen coef_poc_sig= coef_poc * (p_poc <= $PThresh)
gen coef_asian_sig= coef_asian * (p_asian <= $PThresh)
gen coef_native_sig= coef_native * (p_native <= $PThresh)
gen coef_hisp_sig= coef_hisp * (p_hisp <= $PThresh)

preserve 
graph bar coef_female_sig coef_poc_sig, over(state) scale(*.5)
graph export "tables\by_state_coeff.png", replace
 //, label(labsize(vsmall)))
restore

/*##########################################
Tables
############################################*/

#delimit ;
esttab AK AL AR AZ CA IA ID IL IN using "tables\State_table1.csv",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep($InterestVars);
#delimit cr

#delimit ;
esttab MS MT NC ND NE NH NJ NM NV using "tables\State_table2.csv",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep($InterestVars);
#delimit cr

#delimit ;
esttab KS KY LA MA MD ME MI MN MO using "tables\State_table3.csv",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep($InterestVars);
#delimit cr

#delimit ;
esttab NY OH OK OR PA RI SC SD TN using "tables\State_table4.csv",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep($InterestVars);
#delimit cr

#delimit ;
esttab TX UT VA VT WA WI WV WY using "tables\State_table5.csv",
	label se star(* 0.10 ** 0.05 *** 0.01)
	s(State N ymean, 
	label("State" "Observations" "Mean of Dep. Variable"))
	keep($InterestVars);
#delimit cr