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
	loc		root	=	"$data/household_data/nigeria/wave_2/refined"
	loc 	export	=	"$data/household_data/nigeria/wave_2/refined"
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
	*** 113 are missing in master, 9716 matched
	*** most unmerged (849) are from using, meaning we lack production data
	*** per Malawi (rs_plot) we drop all unmerged observations

	drop			if _11a1 != 3
	
* merging in irrigation data
	merge			m:1 hhid plotid using "`root'/pp_sect11b1", generate(_11b1)
	*** only 14 are missing in master, 9717 matched 
	*** we assume these are plots without irrigation
	
	replace			irr_any = 2 if irr_any == . & _11b1 == 1
	*** 14 changes made

	drop			if _11b1 == 2
	
* merging in planting labor data
	merge		m:1 hhid plotid using "`root'/pp_sect11c1", generate(_11c1)
	*** 203 are missing in master, 9528 matched
	*** we will impute the missing values later
	drop			if _11c1 == 2
	*** not going to actually use planting labor in analysis - will omit

* merging in pesticide and herbicide use
	merge		m:1 hhid plotid using "`root'/pp_sect11c2", generate(_11c2)
	*** 41 missing in master, 9690 
	*** we assume these are plots without pest or herb

	replace			pest_any = 2 if pest_any == . & _11c2 == 1
	replace			herb_any = 2 if herb_any == . & _11c2 == 1
	*** 41 changes made for each 
	
	drop			if _11c2 == 2

* merging in fertilizer use
	merge		m:1 hhid plotid using "`root'/pp_sect11d", generate(_11d)
	*** 503 missing from master, 9227 matched 
	*** we will impute the missing values later
	
	drop			if _11d == 2

* merging in harvest labor data
	merge		m:1 hhid plotid using "`root'/ph_secta2", generate(_a2)
	*** 32 missing from master, 9699 matched
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

	drop			_11a1 _11b1 _11c1 _11c2 _11d _a2

	
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
