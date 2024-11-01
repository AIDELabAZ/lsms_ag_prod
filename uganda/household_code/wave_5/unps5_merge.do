* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 12 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	

* assumes
	* previously cleaned household datasets

* TO DO:
	* merge geovars, find a comparable hhid 
	

************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global 	root  		"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global 	logout 		"$data/lsms_ag_prod_data/merged_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps5_merge_plt", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading harvest data, this is our limiting factor
	use 			"$root/2015_agsec4a", clear
	
	isid 			hhid prcid pltid cropid cropid2

* merge in seed and planting date data
	merge 			m:1 hhid prcid pltid cropid using "$root/2015_agsec5a.dta", generate(_sec5a) 
	*** matched 5,669
	*** 1,917 unmatched from master
	
	drop 			if _sec5a != 3
	*** 1,917 dropped
	
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2015_agsec3a", generate(_sec3a)
	*** matched 5,650
	*** 19 unmatched from master

	drop			if _sec3a != 3
	*** 2,,348 dropped
		
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2015_agsec2", generate(_sec2)
	*** matched 5,209
	*** 441 unmatched from master

	drop			if _sec2 != 3
	*** 2,134 dropped
	
	isid 			hhid prcid pltid cropid cropid2

	
************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2015_agsec6.dta", generate(_sec6) 
	*** matched 5,209
	*** 0 unmatched from master
	
	drop 			if _sec6 == 2
	*** 819 dropped - want to keep households w/o livestock

* merge in household size data
	merge 			m:1 hhid using "$root/2015_gsec2h.dta", generate(_gsec2) 
	*** matched 5,209
	*** 0 unmatched from master
	
	drop 			if _gsec2 != 3
	*** 1,430 dropped
	
* merge in electricity data
	merge 			m:1 hhid using "$root/2015_gsec10.dta", generate(_gsec10) 
	*** matched 5,209
	*** 0 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 1,430 dropped

* merge in shock data
	merge 			m:1 hhid using "$root/2015_gsec16.dta", generate(_gsec16) 
	*** matched 5,209
	*** 0 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 1,553 dropped - want to keep households w/o shock
	
* merge in geovars data
	merge 			m:1 hhid_pnl using "$root/2015_geovars.dta", generate(_geovar) 
	*** matched 3,257 matched
	*** 2,391 unmatched from master - most are rotated in hh (2,213)
	
	drop 			if _geovar == 2
	*** 1,632 dropped - want to keep rotated in hh


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

* summarize plot size
	sum				crop_area
	*** mean .52, max 16.9
	
* there are 10 values with 0 plot size yet have harvest
* replace with parcel size
	replace			area_plnt = prclsize if area_plnt == 0
	replace			crop_area = area_plnt*prct_plnt if crop_area == 0
	
* crop area cannot be larger than parcel, convert to missing if 0.01 > than parcel
	replace			crop_area = . if (crop_area - prclsize) > 0.01
	*** 525 replaced
	
* generate counting variable for number of plots in a parcel
	gen				plot_bi = 1
	
	egen			plot_cnt = sum(plot_bi), by(hhid prcid)

* generate tot plot size based on area planted
	egen			plot_tot = sum(crop_area), by(hhid prcid)
	
* compare difference, prclsize should be > than plot_tot
	replace			crop_area = . if (plot_tot - prclsize) > 0.01
	
* replace outliers at top/bottom 5 percent
	sum 			crop_area, detail
	replace			crop_area = . if crop_area >= `r(p95)' | crop_area <= `r(p5)'
	* 2441 changes made
	
* summarize before imputation
	sum 				crop_area, detail
	*** mean .14, sd .10, max .42, min .025
	
* impute missing crop area
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed crop_area // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm crop_area i.admin_2 i.cropid plot_cnt prclsize, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				crop_area_1_, detail	
	*** mean .14, sd .10 max .42

* replace the imputated variable
	replace 			crop_area = crop_area_1_ 
	*** 1,601 changes
	
	drop				mi_miss crop_area_1_
	
	
***********************************************************************
**# 3 - impute harvest quantity
***********************************************************************
	
* summarize harvest quantity prior to imputations
	sum				harv_qty
	*** mean 324, sd 1,806, max 103,000
	
* plot harvest against land
*	twoway			(scatter harv_qty crop_area)
	
* one crazy outlier (103,000 kg of onion)
	replace			harv_qty = . if harv_qty > 100000
	
* generate temporary yield variables
	gen				yield = harv_qty/crop_area

* plot yield against land
*	twoway			(scatter yield crop_area)

* replace outliers at top/bottom 5 percent
	sum 			yield, detail
	replace			harv_qty = . if yield >= `r(p95)' | yield <= `r(p5)'
	* 298 and 282 changes made

* impute missing harvqtykg
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed harv_qty // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm harv_qty i.admin_2 crop_area i.cropid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				harv_qty_1_, detail
	*** mean 223, sd 318, max 2,310

* replace the imputated variable
	replace 			harv_qty = harv_qty_1_
	*** 104 changes
	
	drop 				harv_qty_1_ mi_miss
	
* generate yield variable
	replace				yield = harv_qty/crop_area
	
	sum					yield, detail
	*** mean 1,815, sd 2,324, max 59,305
	
	
	
	fdfs
	

	
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

	drop			_sec2 _sec3a _sec2g _sec3 _sec5a
	
	isid 			hhid prcid pltid cropid cropid2


* close the log
	log	close

/* END */
