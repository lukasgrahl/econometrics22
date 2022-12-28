*Preamble
clear mata
capture log close
clear

cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_4_fe.log", replace tex
use "data\layoff_discr\cps_main_prepro.dta", clear

*tab unemployement by race and month
asdoc tabulate race_cat is_layoff, row nofreq chi2 save(tables\Layoff_tab_state.doc)


/*##########################################
Assumption check
##########################################*/

*corr matrix
correlate /// 
is_female is_poc is_asian is_hisp is_native ///
age age2 new_deathpm new_casespm ///
is_citiz level_educ hh_income contract_type owns_business is_more1job no_child marista housing_kind

/*##########################################
Setting variables and data
############################################*/
* global vars
global TimeCat "hrmonth"

global ControlCatWealth " housing_kind hh_income owns_business "
global ControlCatFam " marista is_citiz " // no_child  
global ConntrolCatJob " level_educ contract_type is_more1job "
global ControlContin " age age2 "
global ControlCovid " new_deathpm new_casespm "
global ControlProf " teleworkable_wage teleworkable_emp "

global InterestVars " is_female is_poc is_asian is_hisp is_native "
global DependVar " is_layoff "
global Cluster " naic_id "

* excludig consecutive observation of households
sort hh_id
quietly by hh_id:  gen dup = cond(_N==1,0,_n)
keep if dup<=1

/*##########################################
Testing 
############################################*/

* Wald test for heteroskedacity
xtset us_state

* base line FE model
xtreg $DependVar $InterestVars, fe
eststo FE

*test for heteroskedacity
xttest3 // We can reject H0: sigma(i)^2 varies, thus there is herteroskedacity

*baseline RE model
xtreg $DependVar $InterestVars, re
eststo RE

* Hausman test: H0 Difference in coefficients not systematic
hausman FE RE // we can reject the H0, differences are systematic thus FE
* However, the Hausman test is unable to account for heteroskedacity, wherefore we additionally perform the Mundlack test

* Mundlack test to identify correct model specification
*##################################

/*##########################################
Mundlack test
############################################*/

*H0: The beta coefficient of state variant variables are zero, suggesting no evidence of correlation between effects and panel variable

* Method suggested by Mundlak, Y. 1978: On the pooling of time series and cross section data. Econometrica 46:69-85., source: https://blog.stata.com/2015/10/29/fixed-effects-or-random-effects-the-mundlak-approach/

preserve
* get level_educ dummies and means
local NNums 38 39 40 41 42 43 44 45 46
foreach x of local NNums{
	display `x'
	
	quietly gen is_level_educ_`x'=1 if level_educ==`x'
	quietly replace is_level_educ_`x'=0 if is_level_educ_`x'==.
	
	bysort us_state: egen mean_level_educ_`x' = mean(is_level_educ_`x')
	display mean_level_educ_`x'
}

* get hh_income dummies and means
local Nums 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
foreach x of local Nums{
	display `x'
	
	quietly gen is_hh_income_`x'=1 if hh_income==`x'
	quietly replace is_hh_income_`x'=0 if is_hh_income_`x'==.
	
	bysort us_state: egen mean_hh_income_`x' = mean(is_hh_income_`x')
	display mean_hh_income_`x'
}

* get age means
bysort us_state: egen mean_age = mean(age)

xtset us_state

quietly xtreg is_layoff age i.(level_educ hh_income) mean_age mean_level_educ_38 mean_level_educ_39 mean_level_educ_40 mean_level_educ_41 mean_level_educ_42 mean_level_educ_43 mean_level_educ_44 mean_level_educ_45 mean_level_educ_46 mean_hh_income_1 mean_hh_income_2 mean_hh_income_3 mean_hh_income_4 mean_hh_income_5 mean_hh_income_6 mean_hh_income_7 mean_hh_income_8 mean_hh_income_9 mean_hh_income_10 mean_hh_income_11 mean_hh_income_12 mean_hh_income_13 mean_hh_income_14 mean_hh_income_15 mean_hh_income_16, vce(robust)

estimates store mundlak

* Test for zero mean of state variant coefficients, we can reject H0, thus assuming H1, implying that FE is the apropriate model
test mean_age mean_level_educ_38 mean_level_educ_39 mean_level_educ_40 mean_level_educ_41 mean_level_educ_42 mean_level_educ_43 mean_level_educ_44 mean_level_educ_45 mean_level_educ_46 mean_hh_income_1 mean_hh_income_2 mean_hh_income_3 mean_hh_income_4 mean_hh_income_5 mean_hh_income_6 mean_hh_income_7 mean_hh_income_8 mean_hh_income_9 mean_hh_income_10 mean_hh_income_11 mean_hh_income_12 mean_hh_income_13 mean_hh_income_14 mean_hh_income_15 mean_hh_income_16

restore

/*##########################################
Fixed effect models
############################################*/

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
quietly estadd local CLU "Yes", replace
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
quietly estadd local CLU "Yes", replace
estadd ysumm, replace

*3: MODEL
* Controll for age and Job
//quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.( $ConntrolCatJob ) ///
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
quietly estadd local CLU "Yes", replace
quietly estadd ysumm, replace


*4: Model
* adding control variables realting to wealth and family
//quietly ///
reghdfe ///
$DependVar $InterestVars ///
$ControlContin ///
i.( $ConntrolCatJob $ControlCatWealth $ControlCatFam ) ///
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
quietly estadd local CLU "Yes", replace
estadd ysumm, replace


*5: MODEL
* adding covid cases and time dimension
//quietly ///
reghdfe ///
$DependVar $InterestVars ///
$ControlContin ///
i.$ConntrolCatJob i.$ControlCatWealth i.$ControlCatFam ///
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
quietly estadd local CLU "Yes", replace
estadd ysumm, replace

*6: Model
* we believe there is a fixed effect of state&time, implying that something (policy) 
* varies over time, and that this needs to be accounted for
//quietly ///
reghdfe ///
$DependVar $InterestVars ///
$ControlContin ///
i.$ConntrolCatJob i.$ControlCatWealth i.$ControlCatFam ///
[aweight=hh_weight] ///
,absorb(us_state#hrmonth naic_id) ///
vce(cluster $Cluster)

eststo M6
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "Yes", replace
quietly estadd local FE_IT "No", replace
quietly estadd local WEIG "Yes", replace
quietly estadd local CLU "Yes", replace
estadd ysumm, replace


*7: Model
* we believe there is some significance to time&profession effects, wherefore 
* we add these alongside the state&time fixed effect
//quietly ///
reghdfe ///
$DependVar $InterestVars ///
$ControlContin ///
i.$ConntrolCatJob i.$ControlCatWealth i.$ControlCatFam ///
[aweight=hh_weight] ///
,absorb(us_state#hrmonth naic_id#hrmonth) ///
vce(cluster $Cluster)

eststo M7
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "No", replace
quietly estadd local FE_IT "Yes", replace
quietly estadd local WEIG "Yes", replace
quietly estadd local CLU "Yes", replace
estadd ysumm, replace

esttab M7

/*##########################################
FE for County instead of state
############################################*/
preserve
drop if county_code==.

* get this to table - different percentages
asdoc tabulate race_cat is_layoff, row nofreq chi2 save(tables\Layoff_tab_county.doc)

// quietly ///
reghdfe ///
$DependVar /// 
$InterestVars ///
$ControlContin ///
i.($ControlCatJob $ConntrolCatFam $ControlCatWealth ) ///
,absorb(county_code#hrmonth naic_id#hrmonth) ///
vce(cluster $Cluster)

eststo M8
quietly estadd local FE_S "No", replace
quietly estadd local FE_ST "Yes", replace
quietly estadd local FE_I "No", replace
quietly estadd local FE_IT "Yes", replace
quietly estadd local WEIG "No", replace
quietly estadd local CLU "Yes", replace
estadd ysumm, replace

restore

/*##########################################
Tables
############################################*/

esttab M* using tables\reg.rtf, replace label onecell compress nogaps nonumbers nodepvars staraux drop("38.level_educ" "1.marista" "1.housing_kind" "3.hrmonth" "1.contract_type" "1.is_more1job") s(FE_S FE_ST FE_I FE_IT WEIG CLU N ymean, label("State FE" "State Month FE" "Industry FE" "Industry Month FE" "Analytical Weights" "Industry Clustering" "Observations" "Mean of Dep. Variable")) addnotes("* Sample weights are provided by CPS and indicate for how many household a surveyed individual is representative")






