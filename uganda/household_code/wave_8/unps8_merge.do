* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 14 Sep 2024
* Edited by: rg
* Stata v.18, mac

* does
	* merges individual cleaned plot datasets together
	* imputes values for continuous variables
	* collapses to wave 3 plot level data to household level for combination with other waves

* assumes
	* previously cleaned household datasets

* TO DO:
	* everything
	

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global 	root  		"$data/household_data/uganda/wave_8/refined"  
	global  export 		"$data/household_data/uganda/wave_8/refined"
	global 	logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/unps8_merge", append

	
* **********************************************************************
* 1 - merge plot level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/2019_agsec5b.dta", clear
	isid 			hhid prcid pltid cropid
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2019_agsec2", generate(_sec2)
	*** matched 5,536, unmatched 2,471 from master
	
	tab 			cropid if _sec2 == 1
	*** mostly from annual crops (banana, coffee, cassava, potato)
	*** but some are maize and beans

	drop			if _sec2 != 3
		
* merging in labor, fertilizer and pest data
	merge			m:1 hhid prcid pltid  using "$root/2019_agsec3b", generate(_sec3a)
	*** 0 unmerged from master

	drop			if _sec3a == 2
	
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
