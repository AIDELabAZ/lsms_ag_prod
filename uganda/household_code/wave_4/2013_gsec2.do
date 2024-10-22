* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 hh information (gsec2)
	* cleans gender and age of household member
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
	log using 		"$logout/2013_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec2.dta", clear
	
* rename variables			
	rename			h2q1 member_number
	rename 			h2q3 gender
	rename 			h2q8 age

* modify format of pid so it matches pid from other files 
	rename			PID pid
	gen 			PID = substr(pid, 2, 5) + substr(pid, 8, 3)
	destring		PID, replace
	
	gen 			hhid = substr(HHID, 2, 5) + substr(HHID, 8,2) + substr(HHID, 11, 2)
	destring		hhid, replace
	
	isid 			hhid PID
	order			hhid, after(gender)
	order			gender, after(hhid)
	
	keep 			hhid PID gender age 

	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
* save file 
	save 			"$export/2013_gsec2.dta", replace	
	
* close the log
	log	close

/* END */
	


	
