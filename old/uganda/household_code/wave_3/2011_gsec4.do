* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 3 hh information (gsec4)
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
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_gsec4_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC4.dta", clear
	
* rename variables			
	rename			h4q7 edu
	rename			HHID hhid
	rename 			PID pid
	rename 			h2q1 member_number
	
	destring 		hhid, replace
	format 			%16.0g hhid
	
	duplicates 		drop hhid pid, force
	isid 			hhid pid

* modify format of pid so it matches pid from other files 
	destring		pid, replace
	format 			pid %16.0g
	
	
	replace			edu = 1 if edu != .
	replace			edu = 0 if edu == .
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid pid edu member_number
	
	order			hhid pid edu member_number
	
	lab var			pid "Person ID"
	
	duplicates 		drop hhid pid, force 
	*** 45 duplicates
	
	isid 			hhid pid
	
	compress
	
* save file 
	save 			"$export/2011_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
