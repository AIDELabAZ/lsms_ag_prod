* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 2 Nov 24
* Edited by: jdm
* Stata v.18.0, mac

* does
	* reads in household Location data (2019_GSEC1)
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
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap 			log 	close
	log 			using 	"$logout/2019_GSEC1", append

	
***********************************************************************
**# 1 - UNPS 2019 (Wave 8) - General(?) Section 1 
***********************************************************************

* import wave 8 season 1
	use				"$root/hh/GSEC1", clear

	isid 			hhid
	rename 			hhidold hhid_7_8
	
* rename variables
	rename			hhidold hh
	rename 			region 	admin_1
	rename 			dc_2018 admin_2
	rename 			sc_2018 admin_3
	rename 			pc_2018 admin_4
	rename 			wgt wgt19
	rename 			urban sector


	tab 			admin_1, missing

	drop if 		admin_1 == .	
	*** 3 observations deleted
	
* drop if missing
	drop if			admin_2 == .
	*** dropped 0 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid hhid_7_8 admin_? wgt19 year sector
	compress
	describe

* save file
	save			"$export/2019_gsec1.dta", replace 

* close the log
	log	close

/* END */	
