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
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap 				log close
	log using 			"$logout/2011_GSEC1_plt", append

	
*+**********************************************************************
**# 1 - UNPS 2011 (Wave 3) - General(?) Section 1 
************************************************************************

* import wave 3 season 1
	use				"$root/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid
	destring		hhid, replace
	format 			%16.0g hhid

	rename 			region admin_1
	rename 			h1aq1 admin_2
	rename 			h1aq3 admin_3
	rename 			h1aq4 admin_4
	rename 			HHS_hh_shftd_dsntgrtd hh_status2011
	rename 			mult wgt11
	***	district variables not labeled in this wave, just coded

	rename 			comm ea
	rename 			urban sector
	tab 			admin_1, missing

* drop if missing
	drop if			admin_2 == ""
	*** dropped 164 observations
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid admin_? ea sector hh_status2011 wgt11
	
	order 			hhid hh_status2011 admin_1 admin_2 admin_3 admin_4 ///
					sector wgt11  hh_status2011 ea
						

	compress
	describe
	summarize

* save file
	save 			"$export/2011_gsec1.dta", replace

* close the log
	log	close

/* END */	
