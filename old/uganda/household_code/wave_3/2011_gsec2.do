* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 25 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 hh information (gsec2)
	* cleans househod member characteristics
		* gender
		* age
	* outputs file for merging with plot owner (agsec2a and agsec2b)

* assumes
	* access to raw data
	* mdesc.ado

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
	log using 		"$logout/2011_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC2.dta", clear
	
* rename variables			
	rename 			h2q3 gender
	rename 			HHID hhid
	rename			h2q8 age
	rename 			h2q1 member_number
	rename 			PID pid

* destring PID and hhid 
	destring		pid, replace
	format 			pid %16.0g
	
	destring		hhid, replace
	format 			hhid %16.0g
	
	destring		member_number, replace
	
	*** hhid and PID do not uniquely idenfify the observations
	
	duplicates 		report hhid pid 
	duplicates		drop hhid pid, force
	*** 72 obsevations dropped
	
	isid 			hhid pid

***********************************************************************
**# 2 - output person data for merge with ag
***********************************************************************
	keep 			hhid pid gender age
	order			hhid hh pid gender age
	
	lab var			hh "Household ID"
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2011_gsec2.dta", replace	
	
***********************************************************************
**# 3 - create household size
***********************************************************************
	
* create counting variable for household members
	gen				hh_size = 1
	
* collapse to household level
	collapse		(sum) hh_size, by(hhid)
	
	lab var			hh_size "Household size"
	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	
	compress
	
* save file 
	save 			"$export/2011_gsec2h.dta", replace	
	
* close the log
	log	close

/* END */
	


	
