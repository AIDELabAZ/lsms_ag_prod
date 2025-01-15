* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 31 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 5 hh information (gsec4)
	* cleans househod member characteristics
		* education
	* outputs file for merging with plot owner (agsec2a and agsec2b)

* assumes
	* access to raw data

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_5/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_gsec4_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec4.dta", clear
	
* rename variables			
	rename			h4q7 edu
	
* modify format of pid so it matches pid from other files 
	gen 			PID = substr(pid, 2, 5) + substr(pid, 8, 3)
	destring		PID, replace
	
	drop 			pid
	rename 			PID pid
	
	isid 			hhid pid
	
* creae education variable
	
	replace			edu = 1 if edu != . & edu !=99
	replace			edu = 0 if edu == .| edu ==99
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid pid edu 
	
	order			hhid pid edu 
	
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2015_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
