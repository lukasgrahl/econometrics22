*Preamble
clear mata
capture log close
clear

cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_5_oxabl.log", replace tex

use "data\layoff_discr\cps_main_prepro.dta", clear

*tab unemployement by race and month
tabulate race_cat is_layoff, row nofreq chi2


/*##########################################
Oaxaca Blinder Decomposition
############################################*/
gen isn_white=1 if is_white==0
replace isn_white=0 if isn_white==.
tab isn_white

keep if hrmonth==5

oaxaca ///
is_layoff /// dependent
gender level_educ age age2 hh_income contract_type teleworkable_emp /// independent
[fweight=hh_weight] /// weights
,by(is_poc) logit /// group var: white

