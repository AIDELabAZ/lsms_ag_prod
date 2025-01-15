* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 5 Nov 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 crop output (2010_AGSEC5A) for the 1st season
	* questionaire 5B is for 2nd season
	* cleans
		* harvest date
		* crops
		* output
	* outputs cleaned harvest date file

* assumes
	* access to all raw data
	* mdesc.ado
	* access to unit conversion file
	* access to cleaned GSEC1

* TO DO:
	* done

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	global conv 	"$data/raw_lsms_data/uganda/conversion_files"  

* open log	
	cap log 		close
	log using 		"$logout/2010_AGSEC5A_plt", append

	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 2 season 1
	use 			"$root/2010_AGSEC5A.dta", clear
	
	rename 			HHID hhid
	rename 			cropID cropid
	rename 			a5aq6c unit
	rename			a5aq6b condition
	rename 			a5aq6e harvmonth	
	
	sort 			hhid prcid pltid cropid
	*** cannot uniquely identify observations by hhid, prcid, or pltid 
	*** there multiple crops on the same plot
	
* harvest start and end dates
	rename			harvmonth harv_str_month
	rename			a5aq6f harv_stp_month


* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 728 observations dropped
	
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
	gen				plt_shck = 1 if a5aq17 != .
	replace			plt_shck = 0 if plt_shck == .
	

************************************************************************
**# 2 - merge kg conversion file and create harvested quantity
************************************************************************
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 2946 from master 
	
* drop from using
	drop 			if _merge == 2

* how many unmatched had a harvest of 0
	tab 			a5aq6a if _merge == 1
	*** 78% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** any condition is mostly missing from unmerged observations
		
	tab 			unit if _merge == 1
	
* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5aq6a == 0 & _merge == 1
	*** 2317 changes
	
* manually replace conversion for the kilograms and sacks
* if the condition is other condition and the observation is unmatched

	*kgs, 49 changes
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
	
	*sack 120 kgs, 12 changes
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
	
	*sack 100 kgs, 164 changes
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
	
	* sack 80 kgs, 6 changes
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
	
	* sack 50 kgs, 17 changes
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
	
		tab 			ucaconversion if _merge == 3 & ucaconversion != a5aq6d 
		*** 7745 different
	
		tab 			medconversion if _merge == 3 & medconversion != a5aq6d 
		*** 5321 different
	
		replace 		ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	
		mdesc 			ucaconversion
		*** 2.9% missing
	
* replace conversion to 1 (kg) if harvest is 0
	replace ucaconversion = 1 if a5aq6a == 0
	*** 7 changes
	
* some missing harvests still have a value for amount sold. Will replace amount sold with 0 if harv qty is missing

	tab a5aq8 if a5aq6a == .
	*** 0 observations
	
	replace a5aq8 = . if a5aq6a == 0 & a5aq7a > 0
	*** 6 observations
	
* drop any observations that remain and still dont have a conversion factor
	drop if ucaconversion == .
	*** 381 observations dropped
	
	drop _merge

* drop crops > 699 and tobacco 
	drop 			if cropid > 699
	drop 			if cropid == 530
	
* Convert harv quantity to kg
	gen 			harv_qty = a5aq6a* ucaconversion
	label var		harv_qty "quantity of crop harvested (kg)"
	mdesc 			harv_qty
	*** 8 missing
	
	drop 			if harv_qty ==.
	
* summarize harvest quantity
	sum				harv_qty
	*** mean 288, max 70,215
	*** 1 crazy value but for onions and is consistent with amount sold
	*** will keep for now	
	
************************************************************************
**# 3 - end matter, clean up to save
************************************************************************

	keep 			hhid prcid pltid harv_qty cropid harv_miss plt_shck ///
					harv_str_month harv_stp_month

* collapse to hhid prcid pltid cropid
* since Production_ID just accounts for different start of hrv month
	collapse 		(sum) harv_qty (mean) harv_str_month harv_stp_month , ///
						by( hhid prcid pltid cropid plt_shck harv_miss)
	* goes from 8,278 to 7,362	

	lab var			plt_shck "=1 if pre-harvest shock"
	lab var			harv_miss "=1 if harvest qty missing"
	
	duplicates 		drop hhid prcid pltid cropid,force
	* 10 obs dropped
	
	isid			hhid prcid pltid cropid
	
	compress


* save file
	save 			"$export/2010_agsec5a.dta", replace

* close the log
	log	close

/* END */
