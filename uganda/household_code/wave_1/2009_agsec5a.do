* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 1 crop output (2009_AGSEC5A) for the 1st season
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
	* conversion and calculate quantity harvested


***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	global conv 	"$data/raw_lsms_data/uganda/conversion_files"  

	
* open log	
	cap log 			close
	log using 			"$logout/2009_AGSEC5A_plt", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 1 season 1
	use 			"$root/2009_AGSEC5A.dta", clear
	
	order 			Hhid
	
	rename 			Hhid hhid
	rename 			A5aq5 cropid
	rename 			A5aq1 prcid
	rename			A5aq3 pltid
	rename			A5aq4 cropname
	rename 			A5aq6c unit_code
	rename			A5aq6b condition_code
	
	sort 			hhid prcid pltid
	*** cannot uniquely identify observations by hhid, prcid, or pltid 
	*** there multiple crops on the same plot
	
* harvest start and end dates
	
* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 1494 obs
	
	tab 			cropname if cropid == .
	drop 			if cropid == .
	*** dropped 1494 observations

* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 497 observations dropped
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		A5aq6a = 0 if A5aq6a == 99999
	*** 1277 changed to zero
	
* replace missing cropharvests with 0
	replace 		A5aq6a = 0 if A5aq6a == .
	*** 234 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** there is still not a unique identifier, will deal with later
	
* create missing harvest dummy
	gen				harv_miss = 1 if A5aq6a == .
	replace			harv_miss = 0 if harv_miss == .

* create ag shock variable 
	gen 			plt_shck = 1 if A5aq17 !=.
	replace 		plt_shck = 0 if plt_shck ==.
	


***********************************************************************
**# 2 - merge kg conversion file and create harvested quantity
***********************************************************************
	
* merge in conversation file
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 3,752 from master, or 30% 
	
* drop from using
	drop 			if _merge == 2

* how many unmatched had a harvest of 0
	tab 			A5aq6a if _merge == 1
	*** 86%, 3217, have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	mdesc 			condition if _merge == 1
	*** all unmatched observations have missing condition_code
	
	tab 			unit if _merge == 1

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if A5aq6a == 0
	*** 3221 changes

* some matched do not have ucaconversions, will use medconversion
	replace 		ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	mdesc 			ucaconversion
	*** 4% missing, 535 missing
	
* Drop the variables still missing ucaconversion
	drop 			if ucaconversion == .
	*** 535 dropped
	
	drop 			_merge
	
	tab				cropname
	*** beans are the most numerous crop being 18% of crops planted
	***	maize is the second highest being 17%
	*** maize will be main crop following most other countries in the study
	
* replace missing harvest quantity to 0
	replace 		A5aq6a = 0 if A5aq6a == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = A5aq6a*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted

* summarize harvest quantity
	sum				harvqtykg
	*** three crazy values, replace with missing
	*** values are not consistent with the amount sold
	
	replace			harvqtykg = . if harvqtykg > 100000
	*** replaced 3 observations

***********************************************************************
**# 9 - end matter, clean up to save
***********************************************************************
	rename 			harvqtykg harv_qty
	keep 			hhid prcid pltid harv_qty cropid harv_miss plt_shck

* collapse to hhid prcid pltid cropid
* since Production_ID just accounts for different start of hrv month
	collapse 		(sum) harv_qty, ///
						by( hhid prcid pltid cropid plt_shck harv_miss)
	* goes from 12,728 to 11,579		

	lab var			plt_shck "=1 if pre-harvest shock"
	lab var			harv_miss "=1 if harvest qty missing"
	
	duplicates 		drop hhid prcid pltid cropid,force
	* end up with 11,505 observations
	
	isid			hhid prcid pltid cropid
	
	compress


* save file
	save 			"$export/2009_agsec5a.dta", replace


* close the log
	log	close

/* END */
