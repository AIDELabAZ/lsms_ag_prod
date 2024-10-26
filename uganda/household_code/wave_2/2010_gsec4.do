* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 1 hh information (gsec4)
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
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2010_gsec4_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC4.dta", clear
	
* rename variables			
	rename			h4q7 edu
	rename			HHID hhid

* modify format of pid so it matches pid from other files 
	destring		PID, replace
	rename 			PID pid
	format 			pid %16.0g	

* generate member_number from PID	
	gen 			member_number = mod(pid, 100)
	mdesc 			member_number

	duplicates 		drop hhid member_number, force
	*** 11 observations drop 
	isid 			hhid member_number
		
	isid 			hhid pid

* generate education variable
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
	
	compress
	
* save file 
	save 			"$export/2010_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
