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
**# 0 - setup
***********************************************************************

* define paths
	loc		root	=	"$data/household_data/nigeria/wave_1/refined"
	loc 	export	=	"$data/household_data/nigeria/wave_1/refined"
	loc 	logout	=	"$data/household_data/nigeria/logs"

* open log
	cap 	log 	close
	log 	using 	"`logout'/ghsy2_merge", append

	
***********************************************************************
**# 1 - merge plot level data sets together
***********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/ph_secta3.dta", clear

	isid			cropplot_id
	
* merge in plot size data
	merge 			m:1 hhid plotid using "`root'/pp_sect11a1", generate(_11a1)
	*** matched 9760, failed to match 80 from master and 972 from using
	*** per Malawi (rs_plot) we drop all unmerged observations

	drop			if _11a1 != 3
	
* merging in irrigation data
	merge			m:1 hhid plotid using "`root'/pp_sect11b", generate(_11b)
	*** matched 9704 and failed to match 56 from master and 917 from using
	*** we assume these are plots without irrigation
	
	replace			irr_any = 2 if irr_any == . & _11b == 1
*** 56 changes made

	drop			if _11b == 2
	
* merging in pesticide and herbicide use
	merge		m:1 hhid plotid using "`root'/pp_sect11c", generate(_11c)
	***matched 9688, failed to match 72 from master and 822 from using
	*** we assume these are plots without pest or herb

	replace			pest_any = 2 if pest_any == . & _11c == 1
	replace			herb_any = 2 if herb_any == . & _11c == 1
	*** 72 changes made for each 
	
	drop			if _11c == 2
	
* merging in fertilizer use
	merge		m:1 hhid plotid using "`root'/pp_sect11d", generate(_11d)
	*** 567 missing from master, 9193 matched 
	*** we will impute the missing values later
	
	drop			if _11d == 2

* merging in harvest labor data
	merge		m:1 hhid plotid using "`root'/ph_secta2", generate(_a2)
	*** 582 missing from master, 9178 matched
	*** we will impute the missing values later
	*** only going to include harvest labor in analysis - will include this and rename generally
	*** can revisit this later

	drop			if _a2 == 2

* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if irr_any == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped

	drop			_11a1 _11b _11c _11c _11d _a2

	
***********************************************************************
**# 1b - create total farm and maize variables
***********************************************************************

* rename some variables
	rename			hrv_labor labordays
	rename			fert_use fert

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

	isid			cropplot_id
	
* close the log
	log	close

/* END */
