* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 10 Oct 2024
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

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/2015_agsec5a.dta", clear
	isid 			hhid prcid pltid cropid
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2015_agsec2", generate(_sec2)
	*** matched 6,546, unmatched 428 from master

	drop			if _sec2 != 3
	
	*merge m:1 		hhid prcid "$root/2015_agsec2_plt", generate(_sec2gender)
	
* merging in labor, fertilizer and pest data
	merge			m:1 hhid prcid pltid  using "$root/2015_agsec3a", generate(_sec3a)
	*** 12 unmatched from master

	drop			if _sec3a == 2
	
	merge m:1 		hhid prcid pltid using "$root"
	
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

	drop			_sec2 _sec3a
	
	isid 			hhid prcid pltid cropid


* close the log
	log	close

/* END */
