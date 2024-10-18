* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 17 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* merges AGSEC2A with hh roster information (ownership rights)
	* reads Uganda wave 1 hh information (AGSEC2A)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_agsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/2009_AGSEC2A.dta", clear
	

* rename variables and prepare for merging 
	rename 			Hhid hhid
	rename			A2aq2 prcid
	rename 			A2aq26a member_number
	
***********************************************************************
**# 2 - merge with hh information 
***********************************************************************	

	merge m:1 		hhid member_number using "$export/2009_gsec2_plt.dta"
	* 134 unmatched from master 
	
	drop 			if _merge == 2
	count 			if _merge ==1 & member_number !=.
	* 7 member_number that are not missing 
	
	mdesc 			member_number
	*** 127 observations
	
	rename 			PID ownshp_rght_a
	drop 			_merge

	
	keep 			hhid hh prcid gender ownshp_rght_a A2aq26b member_number
	rename 			member_number member_number_a
	
	
	rename			gender gender_own_a
	rename			A2aq26b member_number

	merge m:1 		hhid member_number using "$export/2009_gsec2_plt.dta"
	** 2,174 unmatched from master 
	
	count 			if _merge ==1 & member_number ==.
	
	rename			gender gender_own_b
	rename 			PID ownshp_rght_b
	rename 			member_number member_number_b
	
	drop if 		_merge == 2
	drop 			_merge
	
	order 			member_number_b, after(gender_own_a)
	
* 2 hh have missing ownshp_rght_a but have a hh member in ownshp_rght_b
	replace 		member_number_a = member_number_b if ownshp_rght_a =="" & ownshp_rght_b !="" & gender_own_a ==.
	replace 		member_number_b =. if  ownshp_rght_a =="" & ownshp_rght_b !="" & gender_own_a ==.
	
	
	replace 		ownshp_rght_a = ownshp_rght_b if ownshp_rght_a =="" & & ownshp_rght_b !="" & gender_own_a ==.
	replace 		ownshp_rght_b = "" if (ownshp_rght_a == ownshp_rght_b) & gender_own_a ==.
	
	
	replace 		gender_own_a = gender_own_b if gender_own_a==. & ownshp_rght_b =="" &member_number_b ==.
	replace 		gender_own_b = . if gender_own_a !=. & ownshp_rght_b =="" &member_number_b ==.
	
	
* generate two_own and 	joint variables 

	gen 			two_own = 1 if ownshp_rght_a !="" & ownshp_rght_b !=""
	replace 		two_own = 0 if two_own==.
	
	*gen 			joint = 1 if gender_own_a !=. & gender_own_b !=.
	*replace 		joint =0 if joint ==.

***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************
	
	
	compress
	describe
	summarize

* save file
	save			"$export/2009_agsec2g_plt.dta", replace	

* close the log
	log	close

/* END */
	
