* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* merges individual cleaned plot datasets together
	* imputes values for continuous variables
	* collapses to wave 3 plot level data to household level for combination with other waves

* assumes
	* previously cleaned household datasets

* TO DO:
	* geovars merge and imputations
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global 	logout 		"$data/lsms_ag_prod_data/merged_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/unps8_merge", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading harvest data, this is our limiting factor
	use 			"$root/2019_agsec5b", clear
	
	isid 			hhid prcid pltid cropid 

* merge in seed and planting date data
	merge 			m:1 hhid prcid pltid cropid using "$root/2019_agsec4a.dta", generate(_sec4a) 
	*** matched 6,049
	*** 29 unmatched from master
	
	drop 			if _sec4a != 3
	*** 949 dropped
	
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2019_agsec3b", generate(_sec3a)
	*** matched 6,049
	*** 0 unmatched from master

	drop			if _sec3a != 3
	*** 1,743 dropped
		
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2019_agsec2", generate(_sec2)
	*** matched 4,928
	*** 1,121 unmatched from master

	drop			if _sec2 != 3
	*** 1,922 dropped
	
	isid 			hhid prcid pltid cropid 

	
************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2019_agsec6.dta", generate(_sec6) 
	*** matched 4,928
	*** 0 unmatched from master
	
	drop 			if _sec6 == 2
	*** 772 dropped - want to keep households w/o livestock

* merge in household size data
	merge 			m:1 hhid using "$root/2019_gsec2h.dta", generate(_gsec2) 
	*** matched 4,928
	*** 0 unmatched from master
	
	drop 			if _gsec2 != 3
	*** 1,264 dropped
	
* merge in electricity data
	merge 			m:1 hhid using "$root/2019_gsec10.dta", generate(_gsec10) 
	*** matched 4,928
	*** 0 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 1,252 dropped

* merge in shock data
	merge 			m:1 hhid using "$root/2019_gsec16.dta", generate(_gsec16) 
	*** matched 2,239
	*** 2,689 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 301 dropped - want to keep households w/o shock

* merge in geovars data
	*merge 			m:1 hhid_pnl using "$root/2013_geovars.dta", generate(_geovar) 
	*** matched 3,257 matched
	*** 2,391 unmatched from master - most are rotated in hh (2,213)
	
	*drop 			if _geovar == 2
	*** 1,632 dropped - want to keep rotated in hh

akjdpij

* **********************************************************************
* 1b - create total farm and maize variables
* **********************************************************************

* rename some variables
	rename 			cropvalue vl_hrv
	rename			kilo_fert fert
	rename			labor_days labordays

* generate mz_variables
	gen				mz_lnd = plotsize	if cropid == 130
	gen				mz_lab = labordays	if cropid == 130
	gen				mz_frt = fert		if cropid == 130
	gen				mz_pst = pest_any	if cropid == 130
	gen				mz_hrb = herb_any	if cropid == 130
	gen				mz_irr = irr_any	if cropid == 130
	gen 			mz_hrv = vl_hrv	if cropid == 130
	gen 			mz_damaged = 1 		if cropid == 130 & vl_hrv == 0
	
	isid 			hhid prcid pltid cropid

* close the log
	log	close

/* END */
