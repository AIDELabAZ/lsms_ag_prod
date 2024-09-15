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
	loc		root	=	"$data/household_data/niger/wave_2/refined"
	loc 	export	=	"$data/household_data/niger/wave_2/refined"
	loc 	logout	=	"$data/household_data/niger/logs"

* open log
	cap		log 	close
	log 	using 	"`logout'/2014_niger_merge", append

	
***********************************************************************
**# 1 - combine data sets and merge to parcel level
***********************************************************************
	
	
***********************************************************************
**# 1a - merge plot level data sets together
***********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/2014_as2e1p2.dta", clear

	isid 			hhid_y2 field parcel cropid

* no irrigation, no seed use rate
	gen				irr_any = 0
	lab var			irr_any "=1 if any irrigation was used"
	
* merge in plot size data
	merge 			m:1 hhid_y2 field parcel using "`root'/2014_as1p1", generate(_as1p1)
	*** 270 not matched from master out of 1307 not matched 
	*** most unmerged (1037) are from using, meaning we lack production data
	*** per Malawi (rs_plot) we drop all unmerged observations
	
	drop			if _as1p1 != 3

* merging in fertilizer, pesticide, herbicide use and labor
	merge		m:1 hhid_y2 field parcel using "`root'/2014_as2ap1", generate(_as2ap1)
	*** 43 not matched from master, 1130 not matched from using 
	*** we assume these are plots without inputs
	
	replace			pest_any = 0 if pest_any == .
	replace			herb_any = 0 if herb_any == .
	replace			fert_use = 0 if fert_use == .
	replace			fert_any = 0 if fert_any == . & fert_use == 0
	*** 43 changes made
	
	lab def			yesno 0 "No" 1 "Yes"
	lab val			pest_any yesno
	lab val			herb_any yesno
	lab val			fert_any yesno
	lab val			irr_any yesno
	
* 1130 did not match from using 	
	drop			if _as2ap1 == 2

* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped
		
* merging in plant labor data
	merge		m:1 hhid_y2 field parcel using "`export'/2014_as2ap2", generate(_as2ap2)
	*** 130 missing in master, 385 not matched from using 
	*** total of 8259 matched 
	
* 1121 did not match from using 	
	drop			if _as2ap2 == 2
	
* set labor in 130 unmatched observations to zero
	replace			plant_labor = 0 if plant_labor == . & _as2ap2 == 1
	replace			plant_labor_all = 0 if plant_labor_all == . & _as2ap2 == 1
	replace			harvest_labor = 0 if harvest_labor == . & _as2ap2 == 1
	replace			harvest_labor_all = 0 if harvest_labor_all == . & _as2ap2 == 1

* merge in regional information 
	merge m:1		hhid_y2 using "`export'/2014_ms00p1", generate(_ms00p1)
	*** 8389 matched, 0 from master not matched, 1876 from using (which is fine)
	
	keep 			if _ms00p1 == 3
	
	rename 			zd enumeration 
	label var 		region "region"
	
	drop			_as2ap1 _as1p1 _as2ap2 _ms00p1

	
***********************************************************************
**# 1b - create total farm and maize variables
***********************************************************************

* rename some variables
	gen				labordays = prep_labor + plant_labor + harvest_labor
	lab var			labordays "farm labor (days)"
	rename			fert_use fert
	replace			mz_damaged = . if mz_hrv == .

* generate mz_variables
	gen				mz_lnd = plotsize	if mz_hrv != .
	gen				mz_lab = labordays	if mz_hrv != .
	gen				mz_frt = fert		if mz_hrv != .
	gen				mz_pst = pest_any	if mz_hrv != .
	gen				mz_hrb = herb_any	if mz_hrv != .
	gen				mz_irr = irr_any	if mz_hrv != .

	isid 			hhid_y2 field parcel cropid
	
* close the log
	log	close

/* END */
