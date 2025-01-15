* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 2 Nov 24
* Edited by: rg
* Stata v.18.0, mac 

* does
	* reads Uganda wave 7 hh information (gsec2)
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
	global root 	"$data/raw_lsms_data/uganda/wave_7/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_7"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2018_gsec2_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/GSEC2.dta", clear
	
* rename variables			
	rename 			h2q3 gender
	rename 			h2q8 age
	rename 			hhid hh_7_8
	rename 			t0_hhid hhid 
	rename 			PID pid 	

	
***********************************************************************
**# 2 - output person data for merge with ag
***********************************************************************
	
	keep 			hhid hh_7_8 pid gender age
	
	order			hhid hh_7_8 pid gender age
	
	lab var			hh_7_8 "Household ID waves 7 and 8 "
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2018_gsec2.dta", replace	
	
***********************************************************************
**# 3 - create household size
***********************************************************************
	
* create counting variable for household members
	gen				hh_size = 1
	
* collapse to household level
	collapse		(sum) hh_size, by(hhid hh_7_8)
	
	lab var			hh_size "Household size"
	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	
	compress
	
* save file 
	save 			"$export/2018_gsec2h.dta", replace	
	
* close the log
	log	close

/* END */
	


	
