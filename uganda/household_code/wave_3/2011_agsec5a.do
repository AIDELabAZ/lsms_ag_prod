* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 crop output (2011_AGSEC5A) for the 1st season
	* questionaire 5B is for 2nd season
	* cleans
		* harvest date
		* crops
		* output
	* outputs cleaned harvest date file

* assumes
	* mdesc.ado
	* access to raw data
	* access to unit conversion file
	* access to cleaned GSEC1

* TO DO:
	*done

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global 	root  		"$data/raw_lsms_data/uganda/wave_3/raw"  
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global 	logout 		"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	global 	conv 		"$data/raw_lsms_data/uganda/conversion_files"  

* open log	
	cap log 			close
	log using 			"$logout/2011_AGSEC5A_plt", append

	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 3 season 1
	use 			"$root/2011_AGSEC5A.dta", clear
	
	rename 			HHID hhid
	rename 			cropID cropid
	rename			plotID pltid
	rename			parcelID prcid
	rename 			a5aq6c unit
	rename			a5aq6b condition


* harvest start and end dates
	rename			a5aq6e harv_str_month
	rename			a5aq6f harv_stp_month

* one observation is missing pltid
	*** the hhid is 4183002308
	replace		pltid = 5 if hhid == 4183002308 & pltid == .
	*** one change made

	sort 			hhid prcid pltid cropid
	
* drop observations from plots that did not harvest because crop was immature
	drop if a5aq5_2 == 1
	*** 1484 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 669
	*** 2,579 observations dropped
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		a5aq6a = 0 if a5aq6a == 99999
	*** 0 changed to zero
	
* replace missing cropharvests with 0
	replace 		a5aq6a = 0 if a5aq6a == .
	*** 8 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** zero dropped, still not unique ID

* create missing harvest dummy
	gen				harv_miss = 1 if a5aq6a == .
	replace			harv_miss = 0 if harv_miss == .
	
* create ag shock variable
	gen				plt_shck = 1 if a5aq22 != .
	replace			plt_shck = 0 if plt_shck == .
	
* unique identifier
	isid 			hhid prcid pltid productionID cropid
	
************************************************************************
**# 2 - create harvested quantity
************************************************************************

* convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	*** however these are not consistent even within crop-condition
	*** DON'T USE
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 340 from master 
	
* drop from using
	drop 			if _merge == 2

* how many unmatched had a harvest of 0
	tab 			a5aq6a if _merge == 1
	*** 98% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** 92% say the condition was "other(99)"
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5aq6a == 0 & _merge == 1
	*** 334 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
	
	* sack 80 kgs
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
	
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
	
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 3 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 766 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	

* Convert harv quantity to kg
	gen 			harv_qty = a5aq6a* ucaconversion
	label var		harv_qty "quantity of crop harvested (kg)"
	mdesc 			harv_qty
	*** 0 missing
	
* summarize harvest quantity
	sum				harv_qty
	*** mean 391, max 416,000
	*** 3 crazy value for maze and are not consistent with amount sold
	*** replace to missing (?)
	
	
************************************************************************
**# 3 - end matter, clean up to save
************************************************************************

	keep 			hhid prcid pltid productionID cropid harv_str_month ///
					 harv_stp_month  harv_qty plt_shck harv_miss

* collapse to hhid prcid pltid cropid
* since productionID just accounts for different start of hrv month

	collapse 		(sum) harv_qty ///
					(mean) harv_str_month  harv_stp_month, ///
						by(hhid prcid pltid cropid plt_shck harv_miss)
						
	* goes from 8,295 to 7,253		
	
	lab var			harv_str_month "Harvest start month"
	lab var			harv_stp_month "Harvest stp month"
	lab var			harv_qty "Harvest quantity (kg)"
	lab var			plt_shck "=1 if pre-harvest shock"
	lab var			harv_miss "=1 if harvest qty missing"
		
	duplicates 		drop hhid prcid pltid cropid, force
	isid			hhid prcid pltid cropid
	
		
	compress

* save file
	save			"$export/2011_agsec5a.dta", replace

* close the log
	log	close

/* END */
