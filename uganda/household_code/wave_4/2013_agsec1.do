* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads in household Location data (2013_AGSEC1) for the 1st season
	* cleans political geography locations
	* outputs file of location for merging with other ag files that lack this info

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
	log using 		"$logout/2013_AGSEC1_plt", append

	
***********************************************************************
**# 1 - UNPS 2013 (Wave 4) - Section 1 
***********************************************************************

* import wave 4 season 1
	use				"$root/agric/AGSEC1", clear

* rename variables
	isid 			HHID
	rename			HHID hhid

	rename 			district_name district
	rename 			subcounty_name subcounty
	rename 			parish_name parish
	rename 			wgt wgt13
	rename			HHID_old hhid_pnl

* drop if missing
	drop if			district == ""
	*** dropped 0 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hh hhid region district subcounty parish ///
						 wgt13 hhid_pnl rotate ea 

	compress
	describe
	summarize

* save file
	save			"$export/2013_agsec1.dta", replace 

* close the log
	log	close

/* END */	
