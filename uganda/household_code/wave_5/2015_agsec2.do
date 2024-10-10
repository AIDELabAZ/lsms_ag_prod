* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 10 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	* merges AGSEC2A with hh roster information (ownership rights)
	* reads Uganda wave 5 hh information (AGSEC2A)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_5/raw"  
	global export 	"$data/household_data/uganda/wave_5/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_agsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/agric/AGSEC2A.dta", clear
	

* rename variables and prepare for merging 
	rename 			HHID hhid
	rename			parcelID prcid
	rename 			a2aq24a PID
	
***********************************************************************
**# 2 - merge with hh information 
***********************************************************************	

	merge m:1 		hhid PID using "$export/2015_gsec2_plt.dta"
	* 848 unmatched from using 
	
	drop 			if _merge == 2
	count 			if _merge ==1 & PID !=.
	* 118 PID that are not missing 
	
	rename 			PID ownshp_rght_a
	drop 			_merge
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

	
	keep 			hhid hh prcid member_number gender ownshp_rght_a a2aq24b
	
	rename			gender gender_own_a
	rename			a2aq24b PID

	merge m:1 		hhid PID using "$export/2015_gsec2_plt.dta"
	rename			gender gender_own_b
	rename 			PID ownshp_rght_b
	
	drop if 		_merge == 2
	drop 			_merge
	
	gen 			two_own = 1 if ownshp_rght_a !=. & ownshp_rght_b !=.
	replace 		two_own = 0 if two_own==.
	
	gen 			joint = 1 if gender_own_a !=. & gender_own_b !=.
	replace 		joint =0 if joint ==.
	
	
	
	compress
	describe
	summarize

* save file
	save			"$export/2015_agsec2_plt.dta", replace	

* close the log
	log	close

/* END */
	
