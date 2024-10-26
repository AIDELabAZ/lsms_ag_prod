* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 24 Oct 2024
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
	global 	root  		"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global 	logout 		"$data/lsms_ag_prod_data/merged_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps2_merge", append

	
***********************************************************************
**# 1 - merge plot level data sets together
***********************************************************************

* start by loading harvest data, since this is our limiting factor
	use 			"$root/2010_agsec5a.dta", clear

	isid 			hhid prcid pltid cropid
	
* merge in plot size data and irrigation data
	merge 			m:1 hhid prcid pltid cropid using "$root/2010_agsec4a.dta", generate(_sec4a) 
	*** matched 9,550
	*** unmatched from master 74
	drop 			if _sec4a != 3
		
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2010_agsec3a", generate(_sec3a)
	*** 28 unmatched from master

	drop			if _sec3a != 3
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2010_agsec2", generate(_sec2)
	*** matched 9,248
	*** 274 unmatched from master

	drop			if _sec2 != 3
	*** 621 dropped
	
	isid 			hhid prcid pltid cropid 

************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2010_agsec6.dta", generate(_sec6) 
	*** matched 6,265
	*** 2,983 unmatched from master
	
	drop 			if _sec6 == 2
	*** 120 dropped - want to keep households w/o livestock

* merge in household size data
	merge 			m:1 hhid using "$root/2010_gsec2h.dta", generate(_gsec2) 
	*** matched 9,248
	*** 0 unmatched from master
	
	drop 			if _gsec2 != 3
	*** 702 dropped
	
* merge in electricity data
	merge 			m:1 hhid using "$root/2010_gsec10.dta", generate(_gsec10) 
	*** matched 9,088
	*** 160 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 823 dropped

* merge in shock data
	merge 			m:1 hhid using "$root/2010_gsec16.dta", generate(_gsec16) 
	*** matched 9,012
	*** 76 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 698 dropped - want to keep households w/o shock

* merge in geovars data
	merge 			m:1 hhid using "$root/2010_geovars.dta", generate(_geovar) 
	*** matched 9,088 matched
	*** 0 unmatched from master
	
	drop 			if _geovar == 2
	*** 742 dropped 
	
***********************************************************************
**# 2 - impute crop area planted
***********************************************************************

* there are GPS measures at parcel-level 
* however, unlike every other LSMS country there is no plot-level GPS 
* we could use GPS parcel-level measures, which can be >>> than a plot
* because of this often large difference, using GPS parcel would results in
* yields much lower than they really are
* instead we will use self-reported plot-level size, despite its problems
* we apply this consistently to all rounds in UGA
	
	
	
***********************************************************************
**# 3 - impute harvest quantity
***********************************************************************
	

	
	
	
	
	
aaaaa
	
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
