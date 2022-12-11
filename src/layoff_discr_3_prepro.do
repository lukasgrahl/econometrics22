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

* reducing telework data to naic 2 digits, which represent broader categories 
* this allows us to cluster later on on us_stata#naic_2dig, as otherwise to few clusters
tostring naic_id, gen(_naic)
replace _naic=substr(_naic ,1,1)+substr(_naic ,1,1)
destring _naic, gen(naic_2dig)
drop _naic

rename census_id job_ind_naics
rename description naic_description
sort job_ind_naics

save "data\layoff_discr\naic_tel.dta", replace

/*##########################
Covid data by state
############################*/

* merge telework index on main data - 54 missing values due to job_ind_naics
* data link: https://github.com/jdingel/DingelNeiman-workathome/blob/master/national_measures/output/NAICS3_workfromhome.csv
use "data\layoff_discr\cps_main_prepro.dta", clear
sort job_ind_naics
merge m:1 job_ind_naics using "data\layoff_discr\naic_tel.dta", generate(gh)
replace	job_ind_naics=. if job_ind_naics==-1

* dropping 77 missing naics
drop if job_ind_naics==.
save "data\layoff_discr\cps_main_prepro.dta", replace

* merge covid data
* data link: https://data.cdc.gov/Case-Surveillance/United-States-COVID-19-Cases-and-Deaths-by-State-o/9mfq-cb36/data
* data by zip code: https://catalog.data.gov/dataset/covid-19-cases-tests-and-deaths-by-zip-code
*zip cod is missing for 25% of total data

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
* no of children - not enough information
* single parent
// gen is_single=0
// gen is_single_par=0
// replace is_single=1 if marista!=1 | marista!=2
// replace is_single_par=1 if is_single==1 & no_child>0

* age squared
gen age2=age^2

* is black, is hispanic
gen is_native=1 if race==3 | race==5 
replace is_native=0 if is_native==.

gen is_poc=1 if race==6 | race==2 | race==10
replace is_poc=0 if is_poc==.

gen is_asian=1 if race==4 | race==8 | race==11
replace is_asian=0 if is_asian==.

gen is_hisp=1 if race==9 | race==12 | race==14
replace is_hisp=0 if is_hisp==.

gen is_white=1 if is_native==0 & is_poc==0 & is_asian==0 & is_hisp==0
replace is_white=0 if is_white==.

gen _race="white"
replace _race="native" if is_native==1
replace _race="poc" if is_poc==1
replace _race="asian" if is_asian==1
replace _race="hisp" if is_hisp==1
encode _race, gen(race_cat)

* fill nans
replace is_more1job=2 if is_more1job==-1
replace owns_business=. if owns_business==-1 | owns_business==-2 | owns_business==-3
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

// drop if level_educ==. & hh_income==. & is_more1job==. & no_child==. & contract_type==. & owns_business==.


save "data\layoff_discr\cps_main_prepro.dta", replace


  