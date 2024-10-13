* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 12 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	

* assumes
	* previously cleaned household datasets

* TO DO:
	* everything
	

************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global root 		 "$data/household_data/uganda/wave_5/refined"  
	global export 		 "$data/household_data/uganda/wave_5/refined"
	global logout 		 "$data/household_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps5_merge_plt", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading seed info , since this is our limiting factor
	use 			"$root/2015_agsec4a_plt", clear
	isid 			hhid prcid pltid cropid cropid2
	

* merge harvest quantity and value data
	merge 			m:1 hhid prcid pltid cropid using "$root/2015_agsec5a.dta", generate(_sec5a) 
	*** matched 6,657
	*** unmatched 3,028 from master
	
	drop 			if _sec5a != 3
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2015_agsec2_plt", generate(_sec2)
	*** matched 6,230, unmatched 427 from master

	drop			if _sec2 != 3
	
* merge in ownership data
	merge m:1 		hhid prcid using "$root/2015_agsec2g_plt", generate(_sec2g)
	*** matched 5,893
	*** unmatched from master 1,337 
	
	drop 			if _sec2g !=3
	
* merging in labor, fertilizer and pest data
	merge			m:1 hhid prcid pltid  using "$root/2015_agsec3a_plt", generate(_sec3a)
	*** 8 unmatched from master

	drop			if _sec3a == 2
		

* merge in decision making data and gender data
	merge m:1 		hhid prcid pltid using "$root/2015_agsec3_plt", generate (_sec3)
	*** 8 unmatched from master
	
	drop 			if _sec3 !=3
	
* replace missing binary values
	replace			irr_any = 0 if irr_any == .
	replace			pest_any = 0 if pest_any == .
	replace 		herb_any = 0 if herb_any == .
	replace			fert_any = 0 if fert_any == .

* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if irr_any == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped

	drop			_sec2 _sec3a _sec2g _sec3 
	
	isid 			hhid prcid pltid cropid cropid2


* close the log
	log	close

/* END */
