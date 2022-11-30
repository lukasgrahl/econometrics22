*Preamble
clear mata
capture log close
clear
cd "C:\Users\LukasGrahl\Documents\GIT\econometrics22"
log using "log\layoff_discr_1_load.log", replace tex

*data source: https://data.nber.org/cps-basic2/dta/
* merge data
use "data\layoff_discr\raw\cpsb202001.dta", clear

append using "data\layoff_discr\raw\cpsb202001.dta"
append using "data\layoff_discr\raw\cpsb202003.dta"
append using "data\layoff_discr\raw\cpsb202004.dta"
append using "data\layoff_discr\raw\cpsb202005.dta"
append using "data\layoff_discr\raw\cpsb202006.dta"
append using "data\layoff_discr\raw\cpsb202007.dta"

save "data\layoff_discr\cps_main_load.dta", replace