* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* merges AGSEC2A with hh roster information (ownership rights)
	* reads Uganda wave 2 hh information (AGSEC2A)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_2/raw"  
	global export 	"$data/household_data/uganda/wave_2/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_agsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/2010_AGSEC2A.dta", clear
	

* rename variables and prepare for merging 
	rename 			HHID hhid
	rename 			a2aq26a member_number
	
***********************************************************************
**# 2 - merge with hh information 
***********************************************************************	

	merge m:1 		hhid member_number using "$export/2009_gsec2_plt.dta"
	* 28 unmatched from master 
	
	drop 			if _merge == 2
	count 			if _merge ==1 & PID !=.
	* 0 PID that are not missing 
	
	rename 			PID ownshp_rght_a
	drop 			_merge
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

	
	keep 			hhid hh prcid gender ownshp_rght_a a2aq26b 
	
	rename			gender gender_own_a
	rename			a2aq26b member_number

	merge m:1 		hhid member_number using "$export/2009_gsec2_plt.dta"
	rename			gender gender_own_b
	rename 			PID ownshp_rght_b
	

	drop if 		_merge == 2
	drop 			_merge
	
	gen 			two_own = 1 if ownshp_rght_a !=. & ownshp_rght_b !=.
	replace 		two_own = 0 if two_own==.
	
	gen 			joint = 1 if gender_own_a !=. & gender_own_b !=.
	replace 		joint =0 if joint ==.
	
* there are observations that only have a hh member recorded but in ownshp_rght_b
* move those hh to ownshp_rght_a

	replace 		ownshp_rght_a = ownshp_rght_b  if ownshp_rght_a == . & ownshp_rght_b !=.
	replace 		gender_own_a = gender_own_b if gender_own_a ==. & ownshp_rght_b !=.
	replace 		ownshp_rght_b = . if ownshp_rght_b == ownshp_rght_a
	replace 		gender_own_b =. if gender_own_b == gender_own_a & ownshp_rght_b ==.
	
	drop 			member_number
	
	compress
	describe
	summarize

* save file
	save			"$export/2009_agsec2g_plt.dta", replace	

* close the log
	log	close

/* END */
	
