* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 15 Sep 2024
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
	global root 		 "$data/household_data/uganda/wave_3/refined"  
	global export 		 "$data/household_data/uganda/wave_3/refined"
	global logout 		 "$data/household_data/uganda/logs"
	
* open log
	cap 				log close
	log using 			"$logout/unps3_merge_plt", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading seed info , since this is our limiting factor
	use 			"$root/2011_agsec4a_plt", clear
	isid 			hhid prcid pltid cropid 
	

* merge harvest quantity and value data
	merge 			m:1 hhid prcid pltid cropid using "$root/2011_AGSEC5A_plt.dta", generate(_sec5a) 
	*** matched 9,237
	*** unmatched 1,687 from master
	
	drop 			if _sec5a != 3
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2011_agsec2_plt", generate(_sec2)
	*** matched 8,717
	*** unmatched from master 520 

	drop			if _sec2 != 3
	
* merge in ownership data
	merge m:1 		hhid prcid using "$root/2011_agsec2g_plt", generate(_sec2g)
	*** matched 7,181
	*** unmatched from master 1,526 
	
	drop 			if _sec2g !=3
	
* merging in labor, fertilizer and pest data
	merge			m:1 hhid prcid pltid  using "$root/2011_AGSEC3A_plt", generate(_sec3a)
	*** matched 7,177
	*** 4 unmatched from master 

	drop			if _sec3a !=3
		

* merge in decision making data and gender data
	merge m:1 		hhid prcid pltid using "$root/2011_agsec3_plt", generate (_sec3)
	*** matched 7,177
	
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

	drop			_sec2 _sec3a _sec2g _sec3 _sec5a
	
	isid 			hhid prcid pltid cropid 
* close the log
	log	close

/* END */
