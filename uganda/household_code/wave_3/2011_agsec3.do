* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 14 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* merges agsec2 with decision-maker info  (AGSEC3A)
	* creates gender variables
	* reads Uganda wave 3 (AGSEC3A)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_3/raw"  
	global export 	"$data/household_data/uganda/wave_3/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_agsec3_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/2011_AGSEC3A.dta", clear
	
* rename variables			
	rename 			HHID hhid 
	rename			parcelID prcid
	rename 			a3aq3_3 PID
	rename 			plotID pltid

* change format of vars
	format 			hhid %16.0g
	format 			PID %16.0g
	format 			a3aq3_4a %16.0g
	format 			a3aq3_4b %16.0g
	format 			a3aq3_1 %16.0g
	
	keep 			hhid prcid PID pltid a3aq3_1 a3aq3_2 a3aq3_4a a3aq3_4b

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	
	merge m:1 		hhid PID using "$export/2011_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_single
	rename 			gender gender_single
	drop 			_merge
	
	rename 			a3aq3_4a PID
	merge m:1 		hhid PID using "$export/2011_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_a
	rename 			gender gender_a
	drop 			_merge

	rename 			a3aq3_4b PID
	merge m:1 		hhid PID using "$export/2011_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_b
	rename 			gender gender_b
	drop 			_merge
	
	count 			if  a3aq3_2 == 1 & (mgmt_b !=. & mgmt_a !=.)
	*** no observations
	
	count 			if mgmt_single !=. & gender_single ==.
	*** 94 obs missing gender

	count 			if mgmt_a !=. & gender_a ==.
	*** 100 obs 

	count 			if mgmt_b !=. & gender_b ==.
	*** 101 obs missing 
	
	
* create a joint variable 
	gen 			joint_mgmt = 1 if mgmt_a !=. & mgmt_b !=.
	replace 		joint_mgmt = 0 if joint_mgmt ==.
	
	
	order 			gender_single, after(mgmt_single)
	order 			gender_a, after(mgmt_b)
	order 			gender_b, after(gender_a)


	compress
	describe
	summarize
	
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

* save file
	save			"$export/2011_agsec3_plt.dta", replace	

* close the log
	log	close

/* END */
	
	
	
