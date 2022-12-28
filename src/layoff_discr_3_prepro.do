*Preamble
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_3_prepro.log", replace tex

* load data
use "data\layoff_discr\cps_main_filter.dta", clear


* analyse unemployement by race
replace is_layoff=0 if is_layoff==.
bysort race: tab is_layoff
tab race
save "data\layoff_discr\cps_main_prepro.dta", replace

/*##########################
Tele work index by naic
############################*/

* load and rename telework index data
import delimited "data\layoff_discr\raw\naic_telework_index_map", clear

tostring naic_id, gen(_naic)
replace _naic=substr(_naic ,1,1)+substr(_naic ,1,1)
destring _naic, gen(naic_2dig)
drop _naic

rename census_id job_ind_naics
rename description naic_description
sort job_ind_naics

save "data\layoff_discr\naic_tel.dta", replace

use "data\layoff_discr\cps_main_prepro.dta", clear
sort job_ind_naics
merge m:1 job_ind_naics using "data\layoff_discr\naic_tel.dta", generate(gh)
replace	job_ind_naics=. if job_ind_naics==-1

* dropping 77 missing naics
drop if job_ind_naics==.
save "data\layoff_discr\cps_main_prepro.dta", replace

/*##########################
Covid data by state
############################*/

*get pop data
import delimited "data\layoff_discr\raw\usa_population.csv", varnames(1) groupseparator(,) clear
rename state_abrv us_state_str
drop state
sort us_state_str
save "data\layoff_discr\raw\usa_population_edit.dta", replace

*get covid data
import delimited "data\layoff_discr\raw\usa_covid_cases_out.csv", clear
gen hrmonth=month
rename state us_state_str
keep if year==2020
keep if month==3 | month==4 | month==5 //| month==6 //| month==7

*merge population data
sort us_state_str
merge m:1 us_state_str using "data\layoff_discr\raw\usa_population_edit", generate(ght)

* get covid per 100.000 inhabitants
gen tot_casesp=tot_cases/(population/100000)
gen new_casesp=new_case/(population/100000)
gen tot_deathp=tot_death/(population/100000)
gen new_deathp=tot_death/(population/100000)

* get monthly averages
global XPop "tot_casesp new_casesp tot_deathp new_deathp"
foreach var in $XPop{
	by us_state_str hrmonth, sort: egen `var'm = mean(`var')
	}
keep if day==1

sort us_state_str hrmonth
save "data\layoff_discr\usa_covid.dta", replace

*merge covid to main data
use "data\layoff_discr\cps_main_prepro.dta", clear
decode us_state, gen(us_state_str)

sort us_state_str hrmonth
merge m:1 us_state_str hrmonth using "data\layoff_discr\usa_covid"


/*##############################
edit varialbles
################################*/

* age squared
gen age2=age^2

* is native
gen is_native=1 if race==3 | race==5 
replace is_native=0 if is_native==.
* is poc
gen is_poc=1 if race==6 | race==2 | race==10
replace is_poc=0 if is_poc==.
* is asian
gen is_asian=1 if race==4 | race==8 | race==11
replace is_asian=0 if is_asian==.
* is hisp
gen is_hisp=1 if race==9 | race==12 | race==14
replace is_hisp=0 if is_hisp==.
* is white
gen is_white=1 if is_native==0 & is_poc==0 & is_asian==0 & is_hisp==0
replace is_white=0 if is_white==.

gen _race="white"
replace _race="native" if is_native==1
replace _race="poc" if is_poc==1
replace _race="asian" if is_asian==1
replace _race="hisp" if is_hisp==1
encode _race, gen(race_cat)

* assing 0 to nans
replace is_more1job=2 if is_more1job==-1
label define l_ismore1job 1 "more than 1 job" 2 "1 job only"
label value is_more1job l_ismore1job

replace owns_business=2 if owns_business==-1 | owns_business==-2 | owns_business==-3
label define l_owns_bussiness 1 "owns business" 2 "does not own business"
label value owns_business l_owns_bussiness

replace is_vet=2 if is_vet==-1

* time state cluster var
tostring hrmonth, gen(hrmonth_str)
gen _monthstate=hrmonth_str+us_state_str
encode _monthstate, gen(month_state)


* binary is_uscitiz
gen is_citiz=.
replace is_citiz=0 if is_uscitiz!=5
replace is_citiz=1 if is_uscitiz==5
drop is_uscitiz

* use county code
replace county_code=. if county_code==0

* get binary gender
gen is_female=0
replace is_female=1 if gender==2

* percentage weights
sum hh_weight
gen hh_weight_perc = hh_weight /r(sum)

* all under highschool into one category
replace level_educ=38 if level_educ<=38
label define l_level_educ 38 "12th grade no diploma" 39 "high school grad-diploma or equiv (ged)" 40 "some college but no degree" 41 "associate degree-occupational/vocational" 42 "associate degree-academic program" 43 "bachelor's degree (ex: ba, ab, bs)" 44 "master's degree (ex: ma, ms, meng, med, msw)" 45 "professional school deg (ex: md, dds, dvm)" 46 "doctorate degree (ex: phd, edd)" 
label value level_educ l_level_educ

* label data income
label define l_hh_income 1 "Income: < 5" 2 "Income: 5 > < 7.5"  3 "Income: 7.5 > < 10" 4 "Income: 10 > < 12.5" 5 "Income: 12.5 > < 15" 6 "Income: 15 > < 20" 7 "Income: 20 > < 25" 8"Income: 25 > < 30" 9 "Income: 30 > < 35" 10 "Income: 35 > < 40" 11 "Income: 40 > < 50" 12 "Income: 50 > < 60" 13 "Income: 60 > < 75" 14 "Income: 75 > < 100" 15 "Income: 100 > < 150" 16 "Income: 150 >"
label value hh_income l_hh_income
tab hh_income

*month
label define l_hrmonth 3 "Mar" 4 "Apr" 5 "Mai"
label value hrmonth l_hrmonth
tab hrmonth

* contract type
tab contract_type
label define l_contract_type 1 "full-time" 2 "part-time"
label value contract_type l_contract_type


*housing kind 
label define l_housing_kind 1 "house, apartment, flat" 2 "hu in nontransient hotel, motel, etc." 3 "hu permanent in transient hotel, motel" 4 "hu in rooming house" 5 "mobile home or trailer w/no perm. room added" 6 "mobile home or trailer w/1 or more perm. rooms added" 7 "hu not specified above" 10 "unoccupied tent site or trlr site" 12 "other unit not specified above" 
label value housing_kind l_housing_kind

* tabulate with values and labels
preserve
numlabel `r(names)', add
tab housing_kind
restore

*marista 
label define l_marista 1 "married - spouse present" 2 "married - spouse absent" 3 "widowed" 4 "divorced" 5 "separated" 6 "never married" 
label value marista l_marista

*citizen
label define l_is_citizen 0 "us citizenship" 1 "no us citizenship"
label value is_citiz l_is_citizen

save "data\layoff_discr\cps_main_prepro.dta", replace


  