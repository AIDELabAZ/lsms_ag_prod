* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 crop output (2013_AGSEC5A) for the 1st season
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
	* access to cleaned AGSEC1

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/raw_lsms_data/uganda/wave_4/raw"  
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global 	logout 		"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	global 	conv 		"$data/raw_lsms_data/uganda/conversion_files"  

* open log	
	cap log 			close
	log using 			"$logout/2013_AGSEC5A_plt", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season 1
	use 			"$root/agric/AGSEC5A.dta", clear
		
* order and rename variables
	order			hh
	drop			wgt_X

	rename			hh hhid
	rename			HHID hh
	rename 			cropID cropid
	rename			plotID pltid
	rename			parcelID prcid
	rename 			a5aq6c unit
	rename			a5aq6b condition
	*** during this wave condition = a5aq6b not c
	*** unit is c not b
	
* harvest start and end dates
	rename			a5aq6e harv_str_month
	rename			a5aq6e_1 harv_str_year
	rename			a5aq6f harv_stp_month
	rename			a5aq6f_1 harv_stp_year
	
* two observations are missing pltid
	*** the hhids are 163060401 and 172100401
	*** drop this observations
	
	drop			if pltid ==. & (hh == 163060401| hh == 172100401)
	*** two observations dropped

* drop observations from plots that did not harvest because crop was immature
	drop if 		a5aq5_2 == 1
	*** 2,002 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 6 observations missing
	drop			if cropid == .
	** 6 obs deleted
	
* drop cropid is annual, other, fallow, pasture, and trees
	drop 			if cropid > 699
	*** 2,247 observations deleted 
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		a5aq6a = 0 if a5aq6a == 99999
	*** 0 changed to zero

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
	isid 			hhid prcid pltid Production_ID cropid
	sort 			hhid prcid pltid Production_ID cropid
	
	
***********************************************************************
**# 2 - create harvested quantity
***********************************************************************

* convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	*** however these are not consistent even within crop-condition
	*** DON'T USE

* using valid crop conversion factor file
	merge m:1 	cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 215 from master 
	*** unmatched 673 from using
	
* drop from using
	drop 			if _merge == 2
	*** 613 dropped

* how many unmatched had a harvest of 0
	tab 			a5aq6a if _merge == 1
	*** none have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** this isn't it either 
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab 			unit if _merge == 1, nolabel
	
* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5aq6a == 0 & _merge == 1
	*** 0 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 5 changes
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 0 changes
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 2 changes
	
	* sack 80 kgs
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
		*** 1 change
	
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 5 changes
		
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 9 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 1 change
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 0 changes
		
	* jerrican 3 kgs
		replace 		ucaconversion = 3 if unit == 17 & _merge == 1
		*** 1 change 
		
	* tin 20 kgs
		replace 		ucaconversion = 20 if unit == 20 & _merge == 1
		*** 0 changes
		
	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 4 chnages 

	* 15 kg tub
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 3 changes
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 4 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 1 if unit == 30 & _merge == 1
		*** 0 changes

	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 0 changes 

	* cup 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 32 & _merge == 1		
		*** 1 change
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 4 changes
		
	* basket 10 kg 
		replace 		ucaconversion = 10 if unit == 38 & _merge == 1
		*** 2 changes 

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 2 changes

	* basket 2 kg
		replace 		ucaconversion = 2 if unit == 40 & _merge == 1	
		*** 2 changes
		
	* nomi 1 kg
		replace 		ucaconversion = 1 if unit == 119 & _merge == 1	
		*** 13 changes

	* nomi 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 120 & _merge == 1
		*** 1 change 
		
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 158 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 324 changes made
	
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
	*** mean 287, max 103,000
	*** 1 crazy value but for onions and is consistent with amount sold
	*** will keep for now
	
***********************************************************************
**# 9 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid hh prcid pltid Production_ID cropid harv_str_month ///
						harv_str_year harv_stp_month harv_stp_year hh harv_qty ///
						plt_shck harv_miss

* collapse to hhid prcid pltid cropid
* since Production_ID just accounts for different start of hrv month
	collapse 		(sum) harv_qty ///
					(mean) harv_str_month harv_str_year harv_stp_month harv_stp_year, ///
						by(hh hhid prcid pltid cropid plt_shck harv_miss)
	* goes from 6,359 to 5,649		
	
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
	save			"$export/2013_agsec5a.dta", replace

* close the log
	log	close

/* END */
