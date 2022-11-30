*Preamble
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_2_filter.log", replace tex


* load data
use "data\layoff_discr\cps_main_load.dta"

keep if hrmonth==3 | hrmonth==4 | hrmonth==5 //| hrmonth==6

* filter for all in labour force
count if pemlr==-1 // there are 177,092 casses of -1 - nan
drop if pemlr==-1 | pemlr==7 | pemlr==6 |pemlr==5

*generate layoff flag - all individuals that were not working - also those absent
gen is_layoff=1 if pemlr!=1

* get unemployement stats - check they allign with reality
preserve
replace is_layoff=0 if is_layoff==.
bysort hrmonth: tab is_layoff
restore

* duration of unempl - time to 01.01.20
gen weekmonth=(hrmonth-2)*4.5 // * 4.5 weeks per month ~ avg.
replace pelaydur=0 if pelaydur==-1
replace pelkdur=0 if pelkdur==-1
gen dur_layoff=pelkdur + pelaydur

* get is_recent_layoff - boolean for recent unemployement
replace dur_layoff=. if dur_layoff==0
gen is_relayoff=1 if dur_layoff<=weekmonth

* select only recent layoffs
drop if is_layoff==1 & is_relayoff==.

* sanity check - all lay-offs are also recent lay-offs
count if is_layoff!=is_relayoff
drop is_relayoff

* exclude all army members
keep if peafnow==2

* sanity check - do recent lay-off increaes with month - they do
*##########################
*?? as we have excluded all duplicates this is incremental unemployement 
*##########################
preserve
replace is_layoff=0 if is_layoff==.
bysort hrmonth: tab is_layoff
restore

* check for duplicates: month#hh_id - DUP ACROSS MONTH NOT ACCOUNTED FOR
sort hrhhid hrmonth
quietly by hrhhid hrmonth:  gen dup = cond(_N==1,0,_n)
tab dup
keep if dup<=1

* rename variables
rename hrhhid hh_id
rename ptdtrace race
rename prdthsp hsp_race
rename penatvty birtcountr
rename pemntvty mo_birtcountr
rename pefntvty fa_birtcountrr
rename prcitshp is_uscitiz
rename prinusyr imig_year
// rename prdtind1 job_industry
// rename peio1ocd job_ind_naics
rename peio1icd job_ind_naics
rename prftlf contract_type
rename prtage age
rename pesex gender
rename prnmchld no_child
rename hehousut housing_kind
rename hetenur housing_own
rename hefaminc hh_income // caution has 20% allocation rate
rename hrnumhou hh_no_people // consider also number of members alongside income
rename peeduca level_educ
rename hwhhwgt hh_weight // consider weighing households, for more accuarate sample
rename hubus owns_business
rename gestfips us_state
rename gtcbsa zip_code // use to merge population numbers	
rename gtco zip_code2 // check with zip1 - merge with us_state to obtain actual zip
rename gtcbsast population_dens // major city, balanced, non-metro - pop density
rename pemaritl marista // marital status
rename peafever is_vet // is veteran
rename peafnow is_army // is active military service
rename pemjot is_more1job


global X "hh_id race hrmonth dur_layoff job_ind_naics is_layoff hsp_race birtcountr mo_birtcountr fa_birtcountrr is_uscitiz imig_year contract_type age gender no_child housing_kind housing_own hh_income hh_no_people level_educ hh_weight owns_business us_state zip_code zip_code2 population_dens marista is_vet is_army is_more1job population_dens"

keep $X

save "data\layoff_discr\cps_main_filter.dta", replace


