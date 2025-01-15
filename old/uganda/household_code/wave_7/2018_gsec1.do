* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 2 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads in household Location data (2018_AGSEC1)
	* merges in location info from GSEC1
	* cleans
		* political geography locations
		* survey weights
	* outputs file of location for merging with other ag files that lack this info

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* currently written just to allow me to merge waves 7 and 8 together
	* needs to be adapted for use in cleaning wave 7

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_7/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_7"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap 			log 	close
	log 			using 	"$logout/2018_GSEC1", append

	
***********************************************************************
**# 1 - UNPS 2011 (Wave 3) - General(?) Section 1 
***********************************************************************

* import wave 7 season 1
	use				"$root/hh/GSEC1", clear

* rename variables
	isid 			hhid
	rename			hhid hh_7_8
	rename			t0_hhid hhid
	
	rename			region admin_1
	rename 			district_code admin_2
	rename 			subcounty_code admin_3
	rename 			parish_code admin_4
	rename 			hwgt_wc wgt18
	rename			urban sector

	tab 			admin_1, missing

* drop if missing
	drop if			admin_2 == .
	*** dropped 0 observations
	
	replace				year = 2018
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hh_7_8 hhid year admin_? sector wgt18
	
	compress
	describe
	summarize

* save file
		save		"$export/2018_gsec1.dta", replace 

* close the log
	log	close

/* END */	
