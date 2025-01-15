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
	global		root 		 	"$data/household_data/ethiopia/wave_5/refined"
	global		export 		 	"$data/household_data/ethiopia/wave_5/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"

* open log
	cap log 	close
	log 		using			"$logout/ess5_merge", append


***********************************************************************
**# 1 - merging data sets
***********************************************************************	
	
***********************************************************************
**# 1a - merge crop level data sets together
***********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/PH_SEC9", clear
	
	isid			holder_id parcel field crop
	
* merge in crop labor data - post harvest
	merge 			1:1 holder_id parcel field crop using "$root/PH_SEC10", generate(_10A)
	*** 60 unmerged in master, all other unmerged obs coming from using data
	
	keep 			if _10A == 3
	
* merge in crop labor data - post planting
	merge 			1:1 holder_id parcel field crop using "$root/PP_SEC4", generate(_4A)
	*** all obs not matched from using
	
	drop			if _4A == 2
	

************************************************************************
**# 1b - pulling in prices fom price datasets
************************************************************************	

* merging in sec 11 price data
* merging in ea level price data	
	merge 		m:1 crop_code region zone woreda ea using "$export/w5_sect11_pea.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in woreda level price data	
	merge 		m:1 crop_code region zone woreda using "$export/w5_sect11_pworeda.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in zone level price data	
	merge 		m:1 crop_code region zone using "$export/w5_sect11_pzone.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in region level price data	
	merge 		m:1 crop_code region using "$export/w5_sect11_pregion.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in crop level price data	
	merge 		m:1 crop_code using "$export/w5_sect11_pcrop.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* generating implied crop values, using sec 11 median price whee we have 10+ obs
	gen			croppricei = .
	
	replace 	croppricei = p_ea if n_ea>=10 & missing(croppricei)
	*** 224 replaced
	
	replace 	croppricei = p_woreda if n_woreda>=10 & missing(croppricei)
	*** 0 replaced
	
	replace 	croppricei = p_zone if n_zone>=10 & missing(croppricei)
	*** 822 replaced 
	
	replace 	croppricei = p_region if n_region>=10 & missing(croppricei)
	*** 3,725 replaced
	
	replace 	croppricei = p_crop if missing(croppricei)
	*** 2,407 replaced 

* examine the results
	sum			hvst_qty croppricei
	*** only missing prices for 19 obs
	*** assuming these missing prices all come from the same group of crops
	
	tab crop_code if croppricei != .
	tab crop_code if croppricei == .
	*** missing oats, fennel, sunflower, watermelon

* drop these 19
	drop if		croppricei == .
	
* merging in sec 12 price data	
	drop 		p_ea- n_crop
	
* investigate mean prices by crop	
	tab crop_code, summarize(croppricei) mean freq

	
************************************************************************
**# 1c - finding harvest values
************************************************************************	
	
	summarize
	
* creating harvest values
	generate			hvst_value = hvst_qty*croppricei 

* currency conversion
	replace				hvst_value = hvst_value/28.1249
	lab var				hvst_value "Value of Harvest (2015 USD)"
	

***********************************************************************
**# 1d - merging in plot level input data
***********************************************************************

* merge in crop labor data
	merge 			m:1 holder_id parcel field using "$root/PP_SEC3", generate(_3A)
	*** 0 obs not matched from master

	keep			if _3A == 3
	*** drops 4,097 obs where we had field data but no crop data
	
	
***********************************************************************
**# 1e - create total farm and maize variables
***********************************************************************

* rename some variables
	rename 			hvst_value vl_hrv
	gen				labordays = labordays_plant + labordays_harv
	rename			kilo_fert fert
	rename			pesticide_any pest_any
	rename 			herbicide_any herb_any
	rename			irrigated irr_any

* recode binary variables
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

	isid			holder_id parcel field crop

* close the log
	log	close

/* END */
