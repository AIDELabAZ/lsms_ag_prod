* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 14 Sep 2024
* Edited by: rg
* Stata v.18, mac

* does


* assumes
	* previously cleaned household datasets

* TO DO:
	* everything 
	
	
***********************************************************************
**#0 - setup
***********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_6/refined"
	global export 	"$data/household_data/tanzania/wave_6/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log 		close 
	log 			using "$logout/npsy6_merge", append


***********************************************************************
**#1a - merge plot level data sets together
***********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/2019_AGSEC4A", clear

	isid			sdd_hhid plotnum crop_code

* merge in plot size data
	merge 			m:1 plot_id using "$root/2019_AGSEC2A", generate(_2A)
	*** 155 out of 1453 missing in master 
	*** all unmerged obs came from using data 
	*** meaning we lacked production data
	*** per Malawi (rs_plot) we drop all unmerged observations
	
	drop			if _2A != 3
	
* generate area planted
	replace			plotsize = percent_field * plotsize if percent_field != .
	
* merging in production inputs data
	merge			m:1 plot_id using "$root/2019_AGSEC3A", generate(_3A)
	*** 429 out of 1727 missing in master 
	*** all unmerged obs came from using data 
	*** meaning we lacked production data

	drop			if _3A != 3
	
* fill in missing values
	replace			irrigated = 2 if irrigated == .
	*** 0 changes made
	
* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if irrigated == .
	drop			if herbicide_any == .
	drop			if pesticide_any == .
	*** 0 observations dropped

	drop			_2A _3A
	
***********************************************************************
**#1b - creates total farm and maize variables
***********************************************************************

	rename 			hvst_value vl_hrv
	rename			labor_days	labordays
	rename			kilo_fert fert
	rename			pesticide_any pest_any
	rename 			herbicide_any herb_any
	rename			irrigated irr_any
	
* recode binary variables
	replace			fert_any = 0 if fert_any == 2
	replace			pest_any = 0 if pest_any == 2
	replace			herb_any = 0 if herb_any == 2
	replace			irr_any  = 0 if irr_any  == 2
	
* generate mz_variables
	gen				mz_lnd = plotsize	if mz_hrv != .
	gen				mz_lab = labordays	if mz_hrv != .
	gen				mz_frt = fert		if mz_hrv != .
	gen				mz_pst = pest_any	if mz_hrv != .
	gen				mz_hrb = herb_any	if mz_hrv != .
	gen				mz_irr = irr_any	if mz_hrv != .
	
	isid			sdd_hhid plotnum crop_code

* close the log
	log	close

/* END */
