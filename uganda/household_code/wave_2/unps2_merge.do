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

************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global root 		 "$data/household_data/uganda/wave_2/refined"  
	global export 		 "$data/household_data/uganda/wave_2/refined"
	global logout 		 "$data/household_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps2_merge", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/2010_AGSEC5A.dta", clear

	isid 			hhid prcid pltid cropid
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2010_agsec2.dta", generate(_sec2)
	*** matched 10,953, unmatched 304 from master
	*** for now as per Malawi (rs_plot) we drop all unmerged observations

	drop			if _sec2 != 3
		
* merging in labor, fertilizer and pest data
	merge			m:1 hhid prcid pltid  using "$root/2010_AGSEC3A", generate(_sec3a)
	*** 33 unmerged from master

	drop			if _sec3a != 3
	
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

	
************************************************************************
**# 1b - create total farm and maize variables
************************************************************************

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
	gen 			mz_hrv = vl_hrv		if cropid == 130
	gen 			mz_damaged = 1 		if cropid == 130 & vl_hrv == 0
	
	isid 			hhid prcid pltid cropid

* close the log
	log	close

/* END */
