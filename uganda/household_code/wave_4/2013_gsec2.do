* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 hh information (gsec2)
	* cleans househod member characteristics
		* gender
		* age
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
	rename 			h2q3 gender
	rename 			h2q8 age
	rename			HHID hhid
	
* modify format of pid so it matches pid from other files 
	gen 			pid = substr(PID, 2, 5) + substr(PID, 8, 3)
	destring		pid, replace
	
	gen 			hh = substr(hhid, 2, 5) + substr(hhid, 8,2) + substr(hhid, 11, 2)
	destring		hh, replace
	
	isid 			hh pid 

	
***********************************************************************
**# 2 - output person data for merge with ag
***********************************************************************
	
	keep 			hhid hh pid gender age
	
	order			hhid hh pid gender age
	
	lab var			hh "Household ID"
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2013_gsec2.dta", replace	
	
***********************************************************************
**# 3 - create household size
***********************************************************************
	
* create counting variable for household members
	gen				hh_size = 1
	
* collapse to household level
	collapse		(sum) hh_size, by(hhid hh)
	
	lab var			hh_size "Household size"
	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	
	compress
	
* save file 
	save 			"$export/2013_gsec2h.dta", replace	
	
* close the log
	log	close

/* END */
	


	
