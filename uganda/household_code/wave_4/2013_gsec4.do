* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 hh information (gsec4)
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
	global root 	"$data/raw_lsms_data/uganda/wave_4/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2013_gsec4_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec4.dta", clear
	
* rename variables			
	rename			h4q7 edu
	rename			HHID hhid

* modify format of pid so it matches pid from other files 
	gen 			pid = substr(PID, 2, 5) + substr(PID, 8, 3)
	destring		pid, replace
	
	gen 			hh = substr(hhid, 2, 5) + substr(hhid, 8,2) + substr(hhid, 11, 2)
	destring		hh, replace
	
	isid 			hh pid
	
	replace			edu = 1 if edu != .
	replace			edu = 0 if edu == .
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid hh pid edu
	
	order			hhid hh pid edu
	
	lab var			hh "Household ID"
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2013_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
