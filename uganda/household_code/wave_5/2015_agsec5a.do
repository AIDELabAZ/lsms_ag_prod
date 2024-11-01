* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 31 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 5 crop output (2015_AGSEC5A) for the 1st season
	* questionaire 5B is for 1st season
	* cleans
		* harvest date
		* crops
		* output
	* outputs cleaned harvest date file

* assumes
	* mdesc.ado
	* access to raw data
	* access to unit conversion file
	* access to cleaned AGSEC1

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/raw_lsms_data/uganda/wave_5/raw"  
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global 	logout 		"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	global 	conv 		"$data/raw_lsms_data/uganda/conversion_files" 

* open log	
	cap log 				close
	log using 				"$logout/2015_AGSEC5A_plt", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 5 season 1
	
	use 			"$root/agric/AGSEC5B.dta", clear
		
	rename 			cropID cropid
	rename			plotID pltid
	rename			parcelID prcid
	rename 			a5bq6c unit
	rename			a5bq6b condition
	rename			HHID hhid
	
	sort 			hhid prcid pltid cropid
	
* harvest start and end dates
	rename			a5bq6e harv_str_month
	rename			a5bq6e_1 harv_str_year
	rename			a5bq6f harv_stp_month
	rename			a5bq6f_1 harv_stp_year
	
	
* drop observations from plots that did not harvest because crop was immature
	drop 			if a5bq5_2 == 1
	*** 2 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 8 observations missing
	drop			if cropid ==.
	*** 8 obs deleted
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 669
	*** 1,981 observations dropped
	
	
* replace missing cropharvests with 0
	replace 		a5bq6a = 0 if a5bq6a == .
	*** 0 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** zero dropped, still not unique ID
	
* create missing harvest dummy
	gen				harv_miss = 1 if a5bq6a == .
	replace			harv_miss = 0 if harv_miss == .
	
* create ag shock variable
	gen				plt_shck = 1 if a5bq22 != .
	replace			plt_shck = 0 if plt_shck == .
	
* unique identifier
	isid 			hhid prcid pltid cropid Production2_ID
	sort 			hhid prcid pltid cropid Production2_ID
	

	
***********************************************************************
**# 2 - merge kg conversion file and create harvested quantity
***********************************************************************
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 152 from master 
	*** unmatched 764 from using
	*** total unmatched, 916
	
	
* drop from using
	drop 			if _merge == 2
	** 764 obs dropped

* how many unmatched had a harvest of 0
	tab 			a5bq6a if _merge == 1
	*** 0% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** this isn't it either
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab				unit if _merge == 1, nolabel
	

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5bq6a == 0 & _merge == 1
	*** 0 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 1 change
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 1 change
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 0 change
		
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 2 changes
		
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 7 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 1 change
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 1 change
		
	* jerrican 2 kgs
		replace 		ucaconversion = 2 if unit == 18 & _merge == 1
		*** 1 change 
		

	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 1 change 

	* 15 kg plastic Basin
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 0 change
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 3 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 0.5 if unit == 30 & _merge == 1	
		*** 1 change
		
	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 2 changes 
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 3 changes

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 1 change

		
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 127 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 212 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	
* Convert harv quantity to kg
	gen 			harv_qty = a5bq6a* ucaconversion
	label var		harv_qty "quantity of crop harvested (kg)"
	mdesc 			harv_qty
	*** 0 missing
	
* summarize harvest quantity
	sum				harv_qty
	*** mean 252, max 90,000
	
	
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid prcid pltid Production2_ID cropid harv_str_month ///
						harv_str_year harv_stp_month harv_stp_year hh harv_qty ///
						plt_shck harv_miss

* collapse to hhid prcid pltid cropid
* since Production2_ID just accounts for different start of hrv month
	collapse 		(sum) harv_qty ///
					(mean) harv_str_month harv_str_year harv_stp_month harv_stp_year, ///
						by(hhid prcid pltid cropid plt_shck harv_miss)
	* goes from 6,853 to 5,664		
	
	lab var			harv_str_month "Harvest start month"
	lab var			harv_str_year "Harvest start year"
	lab var			harv_stp_month "Harvest stp month"
	lab var			harv_stp_year "Harvest stop year"
	lab var			harv_qty "Harvest quantity (kg)"
	lab var			plt_shck "=1 if pre-harvest shock"
	lab var			harv_miss "=1 if harvest qty missing"
		
	isid			hhid prcid pltid cropid
		
	compress

* save file
	save			"$export/2015_agsec5a.dta", replace

* close the log
	log	close

/* END */
