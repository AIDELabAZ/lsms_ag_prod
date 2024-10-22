* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 13 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does


* assumes
	* previously cleaned household datasets

* TO DO:
	* done
	

************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global 	root  		"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global 	logout 		"$data/lsms_ag_prod_data/merged_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps4_merge_plt", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading harvest data, this is our limiting factor
	use 			"$root/2013_agsec5a", clear
	
	isid 			hhid prcid pltid cropid 

* merge in seed and planting date data
	merge 			m:1 hhid prcid pltid cropid using "$root/2013_agsec4a.dta", generate(_sec4a) 
	*** matched 5,648
	*** only 1 unmatched from master
	
	drop 			if _sec4a != 3
	*** 2,545 dropped
	
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2013_agsec3a", generate(_sec3a)
	*** matched 5,648
	*** 0 unmatched from master

	drop			if _sec3a != 3
	*** 3,032 dropped
		
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2013_agsec2", generate(_sec2)
	*** matched 5,648
	*** 0 unmatched from master

	drop			if _sec2 != 3
	*** 1,327 dropped
	
	isid 			hhid prcid pltid cropid 

	
************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2013_agsec6a.dta", generate(_sec6a) 
	*** matched 1,748
	*** 3,900 unmatched from master - households that do not own livestock
	
	drop 			if _sec6a == 2
	*** 88 dropped - want to keep households w/o livestock

* merge in electricity data
	merge 			m:1 hh using "$root/2013_gsec10.dta", generate(_gsec10) 
	*** matched 5,648
	*** 0 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 1,011 dropped

* merge in shock data
	merge 			m:1 hh using "$root/2013_gsec16.dta", generate(_gsec16) 
	*** matched 5,639
	*** 9 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 1,007 dropped - want to keep households w/o shock

* merge in geovars data
	merge 			m:1 hhid_pnl using "$root/2013_geovars.dta", generate(_geovar) 
	*** matched 3,257 matched
	*** 2,391 unmatched from master - most are rotated in hh (2,213)
	
	drop 			if _geovar == 2
	*** 1,007 dropped - want to keep households w/o shock

***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************

	isid			hhid prcid pltid cropid 
	
	compress
	
* save file 
	save 			"$export/hhfinal_unps5.dta.dta", replace
	
* close the log
	log	close

/* END */
