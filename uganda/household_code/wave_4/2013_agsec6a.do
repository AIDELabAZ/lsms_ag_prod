* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 19 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* livestock ownership information from agric questionaire
	* reads Uganda wave 4 hh information (agsec6a)

* assumes
	* access to raw data
	* mdesc.ado

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
	rename 			a6aq2 livstck
	rename			a6aq3a lvstck_qty
	rename			a6aq3b lvstck_own
	
* create livestock ownership indicator 
	gen 			lvstck = 1 if livstck == 1 & lvstck_qty > 0
	replace 		lvstck = 0 if lvstck ==.

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	keep 			hhid lvstck_own lvstck
	
* save file 
	save 			"$export/2013_agsec6a_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
