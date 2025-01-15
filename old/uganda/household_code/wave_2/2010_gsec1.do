* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads in household location data (GSEC1) for the 1st season
	* cleans
		* political geography locations
		* survey weights
	* outputs file of location for merging with other ag files that lack this info

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* done

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2010_GSEC1_plt", append

	
************************************************************************
**# 1 - UNPS 2009 (Wave 2) - General(?) Section 1 
************************************************************************

* import wave 2 season 1
	use 			"$root/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid
	
	rename 			region admin_1
	rename 			h1aq1 admin_2
	rename 			h1aq3b admin_3
	rename 			h1aq4b admin_4
	rename 			hh_status hh_status2010
	***	district variables not labeled in this wave, just coded
	rename 			h1aq2b county
	
	rename 			comm ea 
	destring 		ea, replace 
	
	rename 			urban sector
	
	tab 			admin_2, missing

* drop if missing
	drop if			admin_2 == ""
	*** dropped 25 observations
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid admin_? ea sector hh_status2010 /// 
					spitoff09_10 spitoff10_11 wgt10 county

	order 			hhid hh_status2010 admin_1 admin_2 admin_3 admin_4 ///
					sector wgt10 spitoff09_10 spitoff10_11 ea
	
	compress
	describe
	summarize

* save file
	save 			"$export/2010_gsec1.dta", replace

* close the log
	log	close

/* END */	
