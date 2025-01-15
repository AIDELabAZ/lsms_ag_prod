* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads in household Location data (2013_AGSEC1)
	* merges in location info from GSEC1
	* cleans
		* political geography locations
		* survey weights
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
	log using 		"$logout/2013_GSEC1_plt", append

	
***********************************************************************
**# 1 - UNPS 2013 (Wave 4) - Section 1 
***********************************************************************

* import wave 4 season 1
	use				"$root/agric/AGSEC1", clear

* rename variables
	isid 			HHID
	
	keep			hh HHID
	
	rename			HHID hhid
	rename			hh HHID
	rename			hhid hh

* merge in GSEC1
	merge 1:1		HHID using "$root/hh/GSEC1"
	*** 0 unmerged in master
	*** 624 unmerged in using - non-ag households
	
	drop if			_merge == 2
	
* drop unneeded variables
	drop			result_code h1aq3b h1aq4b regurb sregion month day ///
						DynID _merge
	
* rename other variables
	rename			HHID hhid
	rename			HHID_old hhid_pnl
	rename			region admin_1
	rename 			h1aq1a admin_2
	rename 			h1aq3a admin_3
	rename 			h1aq4a admin_4
	rename			urban sector
	rename 			wgt_X wgt13
	rename			wgt wgt_pnl

	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	order 			hhid hh hhid_pnl rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector year wgt13 wgt_pnl

	compress
	describe
	summarize

* save file
	save			"$export/2013_agsec1.dta", replace 

* close the log
	log	close

/* END */	
