* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 13 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* merges agsec2 with decision-maker info  (AGSEC3B)
	* creates gender variables
	* reads Uganda wave 5 (AGSEC3B)

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
	log using 		"$logout/2013_agsec3_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/agric/AGSEC3A.dta", clear
	
* rename variables			
	rename 			HHID hhid 
	rename			parcelID prcid
	rename 			a3aq3_3 PID
	rename 			plotID pltid
	
	keep 			hhid prcid PID pltid a3aq3_1 a3aq3_2 a3aq3_4a a3aq3_4b

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	
	merge m:1 		hhid PID using "$export/2013_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_single
	rename 			gender gender_single
	drop 			_merge
	
	rename 			a3aq3_4a PID
	merge m:1 		hhid PID using "$export/2013_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_a
	rename 			gender gender_a
	drop 			_merge

	rename 			a3aq3_4b PID
	merge m:1 		hhid PID using "$export/2013_gsec2_plt.dta"
	drop if 		_merge ==2
	rename 			PID mgmt_b
	rename 			gender gender_b
	drop 			_merge
	
	count 			if  a3aq3_2 == 1 & (mgmt_b !=. & mgmt_a !=.)
	*** one observation 
	
* create a joint variable 
	gen 			joint_mgmt = 1 if mgmt_a !=. & mgmt_b !=.
	replace 		joint_mgmt = 0 if joint_mgmt ==.
	
* replace hh that reported multiple decision-makers but only reported one 
	replace 		mgmt_single = mgmt_a if mgmt_b ==. & mgmt_single ==.
	replace 		gender_single = gender_a if mgmt_single == mgmt_a

	replace 		mgmt_a =. if a3aq3_2 == 2 & mgmt_single !=.
	replace 		gender_a =. if a3aq3_2 == 2 & mgmt_single !=.
	* we don't know gender_b  for 31 observations 
	
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
	save			"$export/2013_agsec3_plt.dta", replace	

* close the log
	log	close

/* END */
	
	
	
