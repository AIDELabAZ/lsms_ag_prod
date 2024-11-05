* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 crop output (2019_AGSEC5A) for the 1st season
	* questionaire 5B is for 2nd season
	* cleans
		* harvest date
		* crops
		* output
	* outputs cleaned harvest date file
	* 3B - 5B are questionaires for the first planting season of 2019 (main)
	* 3A - 5A are questionaires for the second planting season of 2018 (secondary)

* assumes
	* mdesc.ado
	* access to raw data
	* access to unit conversion file
	* access to cleaned AGSEC1

* TO DO:
	* done

	
* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global 	root  		"$data/raw_lsms_data/uganda/wave_8/raw"  
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global 	logout 		"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2019_agsec5b", append
	
	
***********************************************************************
**#1 - import data and rename variables
***********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec5b.dta", clear
	
* rename variables	
	rename 			cropID cropid
	rename			parcelID prcid
	rename 			s5bq06b_1 unit1
	rename 			s5bq06b_2 unit2
	rename			s5bq06c_1 condition1
	rename			s5bq06c_2 condition2
	rename			s5bq06d_1 conversion1
	rename			s5bq06d_2 conversion2
	recast 			str32 hhid

* harvest start and end dates
	rename			s5bq06e_1 harv_str_month1
	rename			s5bq06a_1_1 harv_str_year1
	rename			s5bq06f_1 harv_stp_month1
	rename			s5bq06f_1_1 harv_stp_year1
	
	rename			s5bq06e_2 harv_str_month2
	rename			s5bq06a_1_2 harv_str_year2
	rename			s5bq06f_2 harv_stp_month2
	rename			s5bq06f_1_2 harv_stp_year2
	
	
* sort for ease of access
	describe
	sort 			hhid prcid pltid cropid
	isid 			hhid prcid pltid cropid
	
* drop observations from plots that did not harvest because crop was immature
	drop if s5bq05_2 == 1
	*** 1304 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other
	drop 			if cropid > 699
	*** 1,974 observations dropped
	
* replace missing cropharvests with 0
	replace 		s5bq06a_1 = 0 if s5bq06a_1 == .
	*** 596 changed to zero
	replace 		s5bq06a_2 = 0 if s5bq06a_2 == .
	*** 4,871 changed to zero

* create missing harvest dummy
	gen				harv_miss1 = 1 if s5bq06a_1 == .
	replace			harv_miss1 = 0 if harv_miss1 == .
	
	gen				harv_miss2 = 1 if s5bq06a_2 == .
	replace			harv_miss2 = 0 if harv_miss2 == .
	
* create ag shock variable
	gen				plt_shck1 = 1 if s5bq17_1 != .
	replace			plt_shck1 = 0 if s5bq17_1 == .
	
	gen				plt_shck2 = 1 if s5bq17_2 != .
	replace			plt_shck2 = 0 if s5bq17_2 == .
	
	isid 			hhid prcid pltid cropid
	
	
***********************************************************************
**#2 - merge kg conversion file and create harvested quantity
***********************************************************************

* coffee has 3 identifications in this file, but only one in conversion file 
	replace 		cropid = 810 if cropid == 811
	replace 		cropid = 810 if cropid == 812
	replace			conversion1 = 0 if conversion1 == .
	replace			conversion2 = 0 if conversion2 == .
	
	tab cropid
	***	maize is the most numerous crop being 20%
	*** beans are the second highest being 17% of crops planted
	*** banana food is the third highest being 15% of crops planted
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
	*** harvest quantity is in a variety of measurements and in two conditions
	*** convert quantity to kg for both conditions and add
	gen 			harv_qty = s5bq06a_1*conversion1 + s5bq06a_2*conversion2
	label var		harv_qty "quantity of crop harvested (kg)"
	mdesc 			harv_qty
	*** all converted
	
* summarize harvest quantity
	sum				harv_qty, detail
	*** two crazy values, replace with missing
	
	
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

	keep 			hhid prcid pltid cropid harv_str_month1 harv_str_month2 ///
					harv_str_year1 harv_str_year2 harv_stp_month1 harv_stp_month2 /// 
					harv_stp_year1 harv_stp_year2 harv_qty ///
						plt_shck1 plt_shck2 harv_miss1 harv_miss2

	lab var			harv_str_month1 "Harvest start month condition 1"
	lab var			harv_str_year1 "Harvest start year condition 1"
	lab var			harv_stp_month1 "Harvest stp month condition 1"
	lab var			harv_stp_year1 "Harvest stop year condition 1"
	lab var			harv_qty "Harvest quantity (kg)"
	lab var			plt_shck1 "=1 if pre-harvest shock condition 1"
	lab var			harv_miss1 "=1 if harvest qty missing condition 1"
	lab var			harv_str_month2 "Harvest start month condition 2"
	lab var			harv_str_year2 "Harvest start year condition 2"
	lab var			harv_stp_month2 "Harvest stp month condition 2"
	lab var			harv_stp_year2 "Harvest stop year condition 2"
	lab var			plt_shck2 "=1 if pre-harvest shock condition 2"
	lab var			harv_miss2 "=1 if harvest qty missing condition 2"
	isid			hhid prcid pltid cropid
		
	compress

* save file
	save 			"$export/2019_agsec5b.dta", replace

* close the log
	log	close

/* END */
