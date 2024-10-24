* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads in household location data (2009_GSEC1) for the 1st season
	* cleans
		* political geography locations
		* survey weights
	* outputs file of location for merging with other ag files that lack this info

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2009_GSEC1_plt", append

	
* **********************************************************************
* 1 - UNPS 2009 (Wave 1) - General(?) Section 1 
* **********************************************************************

* import wave 1 season 1
	use 			"$root/2009_GSEC1.dta", clear

* rename variables

	rename 			HHID hhid
	isid 			hhid

	*rename			HHID_old hhid_pnl
	rename			region admin_1
	rename 			h1aq1 admin_2
	rename 			h1aq3 admin_3
	rename 			h1aq4 admin_4
	rename			urban sector
	rename 			hh_status hh_status2009
	***	district variables not labeled in this wave, just coded


* drop if missing
	drop if			admin_2 == .
	*** dropped 6 observations
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid admin_? hh_status2009 wgt09wosplits wgt09 sector
	order 			hhid hh_status2009 admin_1 admin_2 admin_3 admin_4 ///
					sector wgt09 wgt09wosplits

	compress
	describe
	summarize

* save file
	save 			"$export/2009_GSEC1.dta", replace


* close the log
	log	close

/* END */	
