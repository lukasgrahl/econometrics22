*Preamble
clear mata
capture log close
clear

local USStates `"Test"'

foreach x in $USStates{
	display `x'
}