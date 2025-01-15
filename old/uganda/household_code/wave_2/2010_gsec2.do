* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 hh information (gsec2)
	* cleans household member characteristics
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
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2010_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC2.dta", clear
	
* rename variables		
	rename 			HHID hhid 
	rename 			h2q3 gender
	rename 			h2q1 member_number
	rename 			h2q8 age 
	

* modify format of pid so it matches pid from other files 
	destring		PID, replace
	format			PID %16.0g
	rename 			PID pid
	
	isid 			hhid pid
	
	duplicates 		drop hhid member_number, force
	* 20 obs dropped 
	
	isid 			hhid member_number
	
***********************************************************************
**# 2 - output person data for merge with ag
***********************************************************************
	keep 			hhid pid gender member_number age
	
	order			hhid pid member_number gender age
	
	lab var			pid "Person ID"

* save file 
	save 			"$export/2010_gsec2.dta", replace	
	
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
	save 			"$export/2010_gsec2h.dta", replace	
	
* close the log
	log	close

/* END */
	


	
