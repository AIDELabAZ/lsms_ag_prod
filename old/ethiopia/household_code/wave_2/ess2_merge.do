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
	loc root = "$data/household_data/ethiopia/wave_2/refined"
	loc export = "$data/household_data/ethiopia/wave_2/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/ess2_merge", append
	

***********************************************************************
**# 1 - merging data sets
***********************************************************************	
	
***********************************************************************
**# 1a - merge crop level data sets together
***********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/PH_SEC9", clear

	isid			holder_id parcel field crop_code
	
* merge in crop labor data
	merge 			1:1 holder_id parcel field crop_code using "`root'/PH_SEC10", generate(_10A)
	*** all unmerged obs coming from using data w/ labor values = 0
	
	drop 			if _10A == 2
	
* merge in crop labor data
	merge 			1:1 holder_id parcel field crop_code using "`root'/PP_SEC4", generate(_4A)
	*** 12 obs not matched from master
	
	keep			if _4A == 3
	

************************************************************************
**# 1b - pulling in prices fom price datasets
************************************************************************	

* merging in sec 11 price data
* merging in ea level price data	
	merge 		m:1 crop_code region zone woreda ea using "`export'/w2_sect11_pea.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in woreda level price data	
	merge 		m:1 crop_code region zone woreda using "`export'/w2_sect11_pworeda.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in zone level price data	
	merge 		m:1 crop_code region zone using "`export'/w2_sect11_pzone.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in region level price data	
	merge 		m:1 crop_code region using "`export'/w2_sect11_pregion.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in crop level price data	
	merge 		m:1 crop_code using "`export'/w2_sect11_pcrop.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* generating implied crop values, using sec 11 median price whee we have 10+ obs
	gen			croppricei = .
	
	replace 	croppricei = p_ea if n_ea>=10 & missing(croppricei)
	*** 696 replaced
	
	replace 	croppricei = p_woreda if n_woreda>=10 & missing(croppricei)
	*** 257 replaced
	
	replace 	croppricei = p_zone if n_zone>=10 & missing(croppricei)
	*** 3,506 replaced 
	
	replace 	croppricei = p_region if n_region>=10 & missing(croppricei)
	*** 8,742 replaced
	
	replace 	croppricei = p_crop if missing(croppricei)
	*** 4,998 replaced 

* examine the results
	sum			hvst_qty croppricei
	*** still missing prices for 658 obs
	*** assuming these missing prices all come from the same group of crops
	
	tab crop_code if croppricei != .
	tab crop_code if croppricei == .
	*** cactus, fennel, black pepper, ginger, white lumin, beer root, cabbage, carrot, 
	*** cauliflower, garlic, lettuce, spinach, boye/yam, amboshika, timiz kimem
	*** none of these crops appear when price isn't missing

* merging in sec 12 price data	
	drop 		p_ea- n_crop
	
* merging in ea level price data	
	merge 		m:1 crop_code region zone woreda ea using "`export'/w2_sect12_pea.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in woreda level price data	
	merge 		m:1 crop_code region zone woreda using "`export'/w2_sect12_pworeda.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in zone level price data	
	merge 		m:1 crop_code region zone using "`export'/w2_sect12_pzone.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in region level price data	
	merge 		m:1 crop_code region using "`export'/w2_sect12_pregion.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in crop level price data	
	merge 		m:1 crop_code using "`export'/w2_sect12_pcrop.dta"	
	
	drop 		if _merge == 2
	drop 		_merge	
	
* generating implied crop values, using sec 12 median price whee we have 10+ obs	
	replace 	croppricei = p_ea if n_ea>=10 & missing(croppricei)
	*** 0 replaced
	
	replace 	croppricei = p_woreda if n_woreda>=10 & missing(croppricei)
	*** 0 replaced
	
	replace 	croppricei = p_zone if n_zone>=10 & missing(croppricei)
	*** 0 replaced 
	
	replace 	croppricei = p_region if n_region>=10 & missing(croppricei)
	*** 424 replaced
	
	replace 	croppricei = p_crop if missing(croppricei)
	*** 222 replaced 
	
* checking results
	sum			hvst_qty croppricei
	*** only missing prices for 12 obs
	*** assuming these missing prices all come from the same group of crops
	
	tab 		crop_code if croppricei != .
	tab 		crop_code if croppricei == .
	*** still missing prices for fennel, black pepper, cauliflower
	*** 8 obs total - no prices in either sec 11 or 12
	*** will drop
	
	drop		if croppricei == .
	*** 12 obs dropped
	
	drop		p_ea- n_crop
	
* investigate mean prices by crop	
	tab crop_code, summarize(croppricei) mean freq
		
	
************************************************************************
**# 1c - finding harvest values
************************************************************************	
	
	summarize
	
* creating harvest values
	generate			hvst_value = hvst_qty*croppricei 

* currency conversion
	replace				hvst_value = hvst_value/22.672
	lab var				hvst_value "Value of Harvest (2015 USD)"
	

***********************************************************************
**# 1d - merging in plot level input data
***********************************************************************

* merge in crop labor data
	merge 			m:1 holder_id parcel field using "`root'/PP_SEC3", generate(_3A)
	*** 543 obs not matched from master
	
	keep			if _3A == 3
	
	
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

	isid			holder_id parcel field crop_code
	
* close the log
	log	close

/* END */
