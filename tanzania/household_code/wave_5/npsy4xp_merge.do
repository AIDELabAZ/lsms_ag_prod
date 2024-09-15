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


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_5/refined"
	global export 	"$data/household_data/tanzania/wave_5/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log 		close 
	log 			using "$logout/npsy4xp_merge", append


* **********************************************************************
* 1a - merge plot level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/AG_SEC4A", clear

	isid			crop_id

* merge in plot size data
	merge 			m:1 plot_id using "$root/AG_SEC2A", generate(_2A)
	*** 0 out of 5,398 missing in master 
	*** all unmerged obs came from using data 
	*** meaning we lacked production data
	*** per Malawi (rs_plot) we drop all unmerged observations
	
	drop			if _2A != 3
	
* generate area planted
	replace			plotsize = percent_field * plotsize if percent_field != .
	
* merging in production inputs data
	merge			m:1 plot_id using "$root/AG_SEC3A", generate(_3A)
	*** 0 out of 5,398 missing in master 
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
	*** no observations dropped

	drop			_2A _3A
	
* **********************************************************************
* 1b - creates total farm and maize variables
* **********************************************************************

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
	
	isid			crop_id
	
* close the log
	log	close

/* END */
