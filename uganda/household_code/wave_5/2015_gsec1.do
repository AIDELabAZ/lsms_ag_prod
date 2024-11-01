* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 31 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads in household Location data (2015_GSEC1)
	* cleans
		* political geography locations
		* survey weights
	* outputs file of location for merging with other ag files that lack this info


* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_5/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_GSEC1", append

	
***********************************************************************
**# 1 - UNPS 2011 (Wave 5) - Section 1 
***********************************************************************

* import wave 5 season 1
	use				"$root/hh/gsec1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid
	 			
	rename 			region admin_1
	rename 			district admin_2
	rename 			scounty_code admin_3
	rename 			parish_code admin_4
	rename 			hwgt_W5 wgt15
	rename 			urban sector

	tab 			admin_1, missing

* drop if missing
	drop if			admin_2 == .
	*** dropped 0 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hh hhid admin_? wgt15 hwgt_W4_W5 rotate ea sector
						
	order 			hhid hh  admin_1 admin_2 admin_3 ///
						admin_4 ea sector wgt15 hwgt_W4_W5
	compress
	describe
	summarize

* save file
	save			"$export/2015_gsec1.dta", replace		

* close the log
	log	close

/* END */	
