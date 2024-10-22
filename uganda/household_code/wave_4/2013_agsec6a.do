* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 livestock roster (2013_AGSEC6A)
	* produces indicator if households owns livestock

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
	log using 		"$logout/2013_agsec6a_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import LIVESTOCK  info
	use 			"$root/agric/AGSEC6A.dta", clear
	
* rename variables 
	rename 			HHID hhid
	
* create livestock ownership indicator 
	gen 			lvstck = 1 if a6aq2 == 1
	replace 		lvstck = 0 if lvstck ==.

* convert to household level
	collapse (sum)	lvstck, by(hhid)
	
* recode so non-zero is 1
	replace			lvstck = 1 if lvstck > 0
	*** note this should all be 1 since household only answers if they have lvstck
	*** but for some reason 2 households w/o livestock answered
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid lvstck
	
	lab var			lvstck "=1 if household owns livestock"
	
	isid			hhid
	
	compress
	
* save file 
	save 			"$export/2013_agsec6a.dta", replace	
	
* close the log
	log	close

/* END */
	


	
