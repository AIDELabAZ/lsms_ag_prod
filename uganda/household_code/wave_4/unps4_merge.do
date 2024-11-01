* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 1 Nov 2024
* Edited by: jdm
* Stata v.18.5

* does


* assumes
	* previously cleaned household datasets

* TO DO:
	* cleaning
	

************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global 	root  		"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global  export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global 	logout 		"$data/lsms_ag_prod_data/merged_data/uganda/logs"
	
* open log
	cap log 			close
	log using 			"$logout/unps4_merge_plt", append

	
************************************************************************
**# 1 - merge plot level data sets together
************************************************************************

* start by loading harvest data, this is our limiting factor
	use 			"$root/2013_agsec5a", clear
	
	isid 			hhid prcid pltid cropid 

* merge in seed and planting date data
	merge 			m:1 hhid prcid pltid cropid using "$root/2013_agsec4a.dta", generate(_sec4a) 
	*** matched 5,648
	*** only 1 unmatched from master
	
	drop 			if _sec4a != 3
	*** 2,545 dropped
	
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2013_agsec3a", generate(_sec3a)
	*** matched 5,648
	*** 0 unmatched from master

	drop			if _sec3a != 3
	*** 3,032 dropped
		
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2013_agsec2", generate(_sec2)
	*** matched 5,648
	*** 0 unmatched from master

	drop			if _sec2 != 3
	*** 1,327 dropped
	
	isid 			hhid prcid pltid cropid 

	
************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2013_agsec6.dta", generate(_sec6) 
	*** matched 5,648
	*** 0 unmatched from master
	
	drop 			if _sec6 == 2
	*** 389 dropped - want to keep households w/o livestock

* merge in household size data
	merge 			m:1 hhid using "$root/2013_gsec2h.dta", generate(_gsec2) 
	*** matched 5,648
	*** 0 unmatched from master
	
	drop 			if _gsec2 != 3
	*** 1,013 dropped
	
* merge in electricity data
	merge 			m:1 hhid using "$root/2013_gsec10.dta", generate(_gsec10) 
	*** matched 5,648
	*** 0 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 1,011 dropped

* merge in shock data
	merge 			m:1 hhid using "$root/2013_gsec16.dta", generate(_gsec16) 
	*** matched 5,639
	*** 9 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 1,007 dropped - want to keep households w/o shock

* merge in geovars data
	merge 			m:1 hhid_pnl using "$root/2013_geovars.dta", generate(_geovar) 
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
	sum				crop_area, detail
	*** mean .20, max 24
	
* plot distribution
*	kdensity		crop_area
	
* there are 10 values with 0 plot size yet have harvest
* replace with parcel size
	replace			area_plnt = prclsize if area_plnt == 0
	replace			crop_area = area_plnt*prct_plnt if crop_area == 0
	
* generate counting variable for number of plots in a parcel
	gen				plot_bi = 1
	
	egen			plot_cnt = sum(plot_bi), by(hhid prcid)

* generate tot plot size based on area planted
	egen			plot_tot = sum(crop_area), by(hhid prcid)
		
* replace outliers at top/bottom 5 percent
	sum 			crop_area, detail
	replace			crop_area = . if crop_area > `r(p95)' | crop_area < `r(p5)'
	* 492 changes made
	
* summarize before imputation
	sum 				crop_area, detail
	*** mean .16, sd .13, max .61, min .03
	
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
	*** mean .17, sd .13 max .61

* replace the imputated variable
	replace 			crop_area = crop_area_1_ 
	*** 492 changes

* plot new distribution
	kdensity		crop_area
	
	drop				mi_miss crop_area_1_
	
	
***********************************************************************
**# 3 - impute harvest quantity
***********************************************************************
	
* summarize harvest quantity prior to imputations
	sum				harv_qty, detail
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
	replace			harv_qty = . if yield > `r(p95)' | yield < `r(p5)'
	* 565 changes made

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
	*** mean 210, sd 302, max 4,111

* replace the imputated variable
	replace 			harv_qty = harv_qty_1_
	*** 104 changes

* plot harvest against land
*	twoway			(scatter harv_qty crop_area)
	
	drop 				harv_qty_1_ mi_miss
	
* generate yield variable
	replace				yield = harv_qty/crop_area
	
	sum					yield, detail
	*** mean 1,540, sd 1,756, max 19,096

	
***********************************************************************
**# 4 - impute fertilizer quantity
***********************************************************************
	
* summarize fertilizer quantity prior to imputations
	sum				fert_qty, detail
	*** mean 324, sd 1,806, max 103,000
	
* plot harvest against land
*	twoway			(scatter fert_qty crop_area)
	*** none of this looks crazy
	
* because we want to not impose on the data
* and because all these values seem plausible
* we are not imputing anyting for this wave
	
	
***********************************************************************
**# 5 - impute labor quantity
***********************************************************************
	
* summarize fertilizer quantity prior to imputations
	sum				tot_lab, detail
	*** mean 154, sd 179, max 1,676
	
* plot harvest against land
*	twoway			(scatter tot_lab crop_area)	
	*** none of this looks crazy
	
* because we want to not impose on the data
* and because all these values seem plausible
* we are not imputing anyting for this wave	
	

***********************************************************************
**# 6 - restructure variables to make them regression ready
***********************************************************************

* generate crop type groups
	gen				crop = 1 if cropid == 112 // barley
	replace			crop = 2 if cropid == 210 | cropid == 221 | ///
						cropid == 222 | cropid == 223 | cropid == 224 | ///
						cropid == 310 | cropid == 320 // beans/peas/lentils/peanuts
	replace			crop = 3 if cropid == 130 // maize
	replace			crop = 4 if cropid == 141 // millet
	replace			crop = 5 if cropid ==  // nuts
	replace			crop = 6 if cropid ==  // other
	replace			crop = 7 if cropid == 120 // rice
	replace			crop = 8 if cropid == 150 // sorghum
	replace			crop = 9 if cropid == 610 |cropid == 620 |cropid == 630 | ///
						cropid == 640 | cropid == 650 // tubers/root crops
	replace			crop = 10 if cropid == 111 // wheat
	
	
	
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
	gen 			mz_hrv = vl_hrv	if cropid == 130
	gen 			mz_damaged = 1 		if cropid == 130 & vl_hrv == 0
	
* collapse to plot level
	collapse (sum)	vl_hrv plotsize labordays fert ///
						mz_hrv mz_lnd mz_lab mz_frt  ///
			 (max)	pest_any herb_any irr_any fert_any  ///
						mz_pst mz_hrb mz_irr mz_damaged, ///
						by(hhid hh hhid_pnl prcid pltid region ///
						district subcounty parish rotate wgt13)

* replace non-maize harvest values as missing
	tab				mz_damaged, missing
	loc	mz			mz_lnd mz_lab mz_frt mz_pst mz_hrb
	foreach v of varlist `mz'{
	    replace		`v' = . if mz_damaged == . & mz_hrv == 0	
	}	
	replace			mz_hrv = . if mz_damaged == . & mz_hrv == 0		
	drop 			mz_damaged
	*** 4,038 changes made
	
* encode the string location data
	encode 			district, gen(districtdstrng)
	encode			subcounty, gen(subcountydstrng)
	encode			parish, gen(parishdstrng)

	order			hhid hh hhid_pnl prcid pltid region district  ///
						 districtdstrng subcounty subcountydstrng parish ///
						parishdstrng rotate wgt13 vl_hrv ///
						plotsize labordays fert_any fert irr_any ///
						pest_any herb_any mz_hrv mz_lnd mz_lab mz_frt ///
						mz_irr mz_pst mz_hrb
	
	
************************************************************************
**# 2 - impute: total farm value, labor, fertilizer use 
************************************************************************

* ******************************************************************************
* FOLLOWING WB: we will construct production variables on a per hectare basis,
* and conduct imputation on the per hectare variables. We will then create 
* 'imputed' versions of the non-per hectare variables (e.g. harvest, 
* value) by multiplying the imputed per hectare vars by plotsize. 
* This approach relies on the assumptions that the 1) GPS measurements are 
* reliable, and 2) outlier values are due to errors in the respondent's 
* self-reported production quantities
* ******************************************************************************


************************************************************************
**# 2a - impute: total value
************************************************************************
	
* construct production value per hectare
	gen				vl_yld = vl_hrv / plotsize
	assert 			!missing(vl_yld)
	lab var			vl_yld "value of yield (2015USD/ha)"

* impute value per hectare outliers 
	sum				vl_yld
	bysort region :	egen stddev = sd(vl_yld) if !inlist(vl_yld,.,0)
	recode stddev	(.=0)
	bysort region :	egen median = median(vl_yld) if !inlist(vl_yld,.,0)
	bysort region :	egen replacement = median(vl_yld) if  ///
						(vl_yld <= median + (3 * stddev)) & ///
						(vl_yld >= median - (3 * stddev)) & !inlist(vl_yld,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		vl_yldimp = vl_yld
	replace  		vl_yldimp = maxrep if !((vl_yld < median + (3 * stddev)) ///
						& (vl_yld > median - (3 * stddev))) ///
						& !inlist(vl_yld,.,0) & !mi(maxrep)
	tabstat			vl_yld vl_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 168 to 122
						
	drop			stddev median replacement maxrep minrep
	lab var			vl_yldimp	"value of yield (2015USD/ha), imputed"

* inferring imputed harvest value from imputed harvest value per hectare
	generate		vl_hrvimp = vl_yldimp * plotsize 
	lab var			vl_hrvimp "value of harvest (2015USD), imputed"
	lab var			vl_hrv "value of harvest (2015USD)"
	

************************************************************************
**# 2b - impute: labor
************************************************************************

* construct labor days per hectare
	gen				labordays_ha = labordays / plotsize, after(labordays)
	lab var			labordays_ha "farm labor use (days/ha)"
	sum				labordays labordays_ha

* impute labor outliers, right side only 
	sum				labordays_ha, detail
	bysort region :	egen stddev = sd(labordays_ha) if !inlist(labordays_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(labordays_ha) if !inlist(labordays_ha,.,0)
	bysort region :	egen replacement = median(labordays_ha) if ///
						(labordays_ha <= median + (3 * stddev)) & ///
						(labordays_ha >= median - (3 * stddev)) & !inlist(labordays_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				labordays_haimp = labordays_ha, after(labordays_ha)
	replace 		labordays_haimp = maxrep if !((labordays_ha < median + (3 * stddev)) ///
						& (labordays_ha > median - (3 * stddev))) ///
						& !inlist(labordays_ha,.,0) & !mi(maxrep)
	tabstat 		labordays_ha labordays_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 502 to 397
	
	drop			stddev median replacement maxrep minrep
	lab var			labordays_haimp	"farm labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				labordaysimp = labordays_haimp * plotsize, after(labordays)
	lab var			labordaysimp "farm labor (days), imputed"


************************************************************************
**# 2c - impute: fertilizer
************************************************************************

* construct fertilizer use per hectare
	gen				fert_ha = fert / plotsize, after(fert)
	lab var			fert_ha "fertilizer use (kg/ha)"
	sum				fert fert_ha

* impute labor outliers, right side only 
	sum				fert_ha, detail
	bysort region :	egen stddev = sd(fert_ha) if !inlist(fert_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(fert_ha) if !inlist(fert_ha,.,0)
	bysort region :	egen replacement = median(fert_ha) if ///
						(fert_ha <= median + (3 * stddev)) & ///
						(fert_ha >= median - (3 * stddev)) & !inlist(fert_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				fert_haimp = fert_ha, after(fert_ha)
	replace 		fert_haimp = maxrep if !((fert_ha < median + (3 * stddev)) ///
						& (fert_ha > median - (3 * stddev))) ///
						& !inlist(fert_ha,.,0) & !mi(maxrep)
	tabstat 		fert_ha fert_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** mean stays the same 
	
	drop			stddev median replacement maxrep minrep
	lab var			fert_haimp	"fertilizer use (kg/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				fertimp = fert_haimp * plotsize, after(fert)
	lab var			fertimp "fertilizer (kg), imputed"
	lab var			fert "fertilizer (kg)"


************************************************************************
**# 3 - impute: maize yield, labor, fertilizer use 
************************************************************************


************************************************************************
**# 3a - impute: maize yield
************************************************************************

* construct maize yield
	gen				mz_yld = mz_hrv / mz_lnd, after(mz_hrv)
	lab var			mz_yld	"maize yield (kg/ha)"

* maybe imputing zero values	
	
* impute yield outliers
	sum				mz_yld
	bysort region : egen stddev = sd(mz_yld) if !inlist(mz_yld,.,0)
	recode 			stddev (.=0)
	bysort region : egen median = median(mz_yld) if !inlist(mz_yld,.,0)
	bysort region : egen replacement = median(mz_yld) if /// 
						(mz_yld <= median + (3 * stddev)) & ///
						(mz_yld >= median - (3 * stddev)) & !inlist(mz_yld,.,0)
	bysort region : egen maxrep = max(replacement)
	bysort region : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		mz_yldimp = mz_yld, after(mz_yld)
	replace  		mz_yldimp = maxrep if !((mz_yld < median + (3 * stddev)) ///
						& (mz_yld > median - (3 * stddev))) ///
						& !inlist(mz_yld,.,0) & !mi(maxrep)
	tabstat 		mz_yld mz_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 116 to 90
					
	drop 			stddev median replacement maxrep minrep
	lab var 		mz_yldimp "maize yield (kg/ha), imputed"

* inferring imputed harvest quantity from imputed yield value 
	generate 		mz_hrvimp = mz_yldimp * mz_lnd, after(mz_hrv)
	lab var 		mz_hrvimp "maize harvest quantity (kg), imputed"
	lab var 		mz_hrv "maize harvest quantity (kg)"


************************************************************************
**# 3b - impute: maize labor
************************************************************************

* construct labor days per hectare
	gen				mz_lab_ha = mz_lab / mz_lnd, after(labordays)
	lab var			mz_lab_ha "maize labor use (days/ha)"
	sum				mz_lab mz_lab_ha

* impute labor outliers, right side only 
	sum				mz_lab_ha, detail
	bysort region :	egen stddev = sd(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	bysort region :	egen replacement = median(mz_lab_ha) if ///
						(mz_lab_ha <= median + (3 * stddev)) & ///
						(mz_lab_ha >= median - (3 * stddev)) & !inlist(mz_lab_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_lab_haimp = mz_lab_ha, after(mz_lab_ha)
	replace 		mz_lab_haimp = maxrep if !((mz_lab_ha < median + (3 * stddev)) ///
						& (mz_lab_ha > median - (3 * stddev))) ///
						& !inlist(mz_lab_ha,.,0) & !mi(maxrep)
	tabstat 		mz_lab_ha mz_lab_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 550 to 425
	
	drop			stddev median replacement maxrep minrep
	lab var			mz_lab_haimp	"maize labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_labimp = mz_lab_haimp * mz_lnd, after(mz_lab)
	lab var			mz_labimp "maize labor (days), imputed"


************************************************************************
**# 3c - impute: maize fertilizer
************************************************************************

* construct fertilizer use per hectare
	gen				mz_frt_ha = mz_frt / mz_lnd, after(mz_frt)
	lab var			mz_frt_ha "fertilizer use (kg/ha)"
	sum				mz_frt mz_frt_ha

* impute labor outliers, right side only 
	sum				mz_frt_ha, detail
	bysort region :	egen stddev = sd(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	bysort region :	egen replacement = median(mz_frt_ha) if ///
						(mz_frt_ha <= median + (3 * stddev)) & ///
						(mz_frt_ha >= median - (3 * stddev)) & !inlist(mz_frt_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_frt_haimp = mz_frt_ha, after(mz_frt_ha)
	replace 		mz_frt_haimp = maxrep if !((mz_frt_ha < median + (3 * stddev)) ///
						& (mz_frt_ha > median - (3 * stddev))) ///
						& !inlist(mz_frt_ha,.,0) & !mi(maxrep)
	tabstat 		mz_frt_ha mz_frt_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** mean stays the same
	
	drop			stddev median replacement maxrep minrep
	lab var			mz_frt_haimp	"fertilizer use (kg/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_frtimp = mz_frt_haimp * mz_lnd, after(mz_frt)
	lab var			mz_frtimp "fertilizer (kg), imputed"
	lab var			mz_frt "fertilizer (kg)"


************************************************************************
**# 4 - collapse to household level
************************************************************************


************************************************************************
**# 4a - generate total farm variables
************************************************************************

* generate plot area
	bysort			hhid (pltid) : egen tf_lnd = sum(plotsize)
	assert			tf_lnd > 0 
	sum				tf_lnd, detail

* value of harvest
	bysort			hhid (pltid) : egen tf_hrv = sum(vl_hrvimp)
	sum				tf_hrv, detail
	
* value of yield
	generate		tf_yld = tf_hrv / tf_lnd
	sum				tf_yld, detail
	
* labor
	bysort 			hhid (pltid) : egen lab_tot = sum(labordaysimp)
	generate		tf_lab = lab_tot / tf_lnd
	sum				tf_lab, detail

* fertilizer
	bysort 			hhid (pltid) : egen fert_tot = sum(fertimp)
	generate		tf_frt = fert_tot / tf_lnd
	sum				tf_frt, detail

* pesticide
	bysort 			hhid (pltid) : egen tf_pst = max(pest_any)
	tab				tf_pst
	
* herbicide
	bysort 			hhid (pltid) : egen tf_hrb = max(herb_any)
	tab				tf_hrb
	
* irrigation
	bysort 			hhid (pltid) : egen tf_irr = max(irr_any)
	tab				tf_irr
	
	
************************************************************************
**# 4b - generate maize variables 
************************************************************************	
	
* generate plot area
	bysort			hhid (pltid) :	egen cp_lnd = sum(mz_lnd) ///
						if mz_hrvimp != .
	assert			cp_lnd > 0 
	sum				cp_lnd, detail

* value of harvest
	bysort			hhid (pltid) :	egen cp_hrv = sum(mz_hrvimp) ///
						if mz_hrvimp != .
	sum				cp_hrv, detail
	
* value of yield
	generate		cp_yld = cp_hrv / cp_lnd if mz_hrvimp != .
	sum				cp_yld, detail
	
* labor
	bysort 			hhid (pltid) : egen lab_mz = sum(mz_labimp) ///
						if mz_hrvimp != .
	generate		cp_lab = lab_mz / cp_lnd
	sum				cp_lab, detail

* fertilizer
	bysort 			hhid (pltid) : egen fert_mz = sum(mz_frtimp) ///
						if mz_hrvimp != .
	generate		cp_frt = fert_mz / cp_lnd
	sum				cp_frt, detail

* pesticide
	bysort 			hhid (pltid) : egen cp_pst = max(mz_pst) /// 
						if mz_hrvimp != .
	tab				cp_pst
	
* herbicide
	bysort 			hhid (pltid) : egen cp_hrb = max(mz_hrb) ///
						if mz_hrvimp != .
	tab				cp_hrb
	
* irrigation
	bysort 			hhid (pltid) : egen cp_irr = max(mz_irr) ///
						if mz_hrvimp != .
	tab				cp_irr

* verify values are accurate
	sum				tf_* cp_*
	
* collapse to the household level
	loc	cp			cp_*
	foreach v of varlist `cp'{
	    replace		`v' = 0 if `v' == .
	}		
	
* count before collapse
	count
	*** 5,433 obs
	
	collapse 		(max) tf_* cp_*, by(region district districtdstrng ///
						subcounty subcountydstrng parish ///
						parishdstrng rotate wgt13 hhid hh hhid_pnl)

* count after collapse 
	count 
	*** 5,433 to 2,192 observations 
	
* return non-maize production to missing
	replace			cp_yld = . if cp_yld == 0
	replace			cp_irr = 1 if cp_irr > 0	
	replace			cp_irr = . if cp_yld == . 
	replace			cp_hrb = 1 if cp_hrb > 0
	replace			cp_hrb = . if cp_yld == .
	replace			cp_pst = 1 if cp_pst > 0
	replace			cp_pst = . if cp_yld == .
	replace			cp_frt = . if cp_yld == .
	replace			cp_lnd = . if cp_yld == .
	replace			cp_hrv = . if cp_yld == .
	replace			cp_lab = . if cp_yld == .

* verify values are accurate
	sum				tf_* cp_*

* generate new hhid to match with previous rounds
	isid			hh
	isid			hhid
	
	drop			hhid
	format 			%17.0g hhid_pnl
	tostring		hhid_pnl, gen(hhid) format(%17.0g)
	*** should be 860 with missing values
	
* replace them with current wave hhid
	replace			hhid = "" if hhid == "."
	drop 			hhid_pnl
	*** replaced 860 missing observations
	
* create future panel ID variable
	gen				HHID = substr(hh, 1, 6) + substr(hh, 11, 2)
	

************************************************************************
**# 8 - end matter, clean up to save
************************************************************************
	
* verify unique household id
	isid			hh

* label variables
	lab var			hh "Unique ID for wave 4"
	lab var			hhid "Unique previous panel ID"
	lab var			HHID "Unique future panel ID"
	lab var			tf_lnd	"Total farmed area (ha)"
	lab var			tf_hrv	"Total value of harvest (2015 USD)"
	lab var			tf_yld	"value of yield (2015 USD/ha)"
	lab var			tf_lab	"labor rate (days/ha)"
	lab var			tf_frt	"fertilizer rate (kg/ha)"
	lab var			tf_pst	"Any plot has pesticide"
	lab var			tf_hrb	"Any plot has herbicide"
	lab var			tf_irr	"Any plot has irrigation"
	lab var			cp_lnd	"Total maize area (ha)"
	lab var			cp_hrv	"Total quantity of maize harvest (kg)"
	lab var			cp_yld	"Maize yield (kg/ha)"
	lab var			cp_lab	"labor rate for maize (days/ha)"
	lab var			cp_frt	"fertilizer rate for maize (kg/ha)"
	lab var			cp_pst	"Any maize plot has pesticide"
	lab var			cp_hrb	"Any maize plot has herbicide"
	lab var			cp_irr	"Any maize plot has irrigation"

* merge in harvest season
	merge			m:1 region district using "$root/harv_month", force
	
	drop			if _merge == 2
	drop			_merge
	
* replace missing values
	replace			season = 1 if region == 3
	replace			season = 0 if season == .	
	
	drop			districtdstrng  subcountydstrng ///
						parishdstrng harv 

* generate year identifier
	gen				year = 2013
	lab var			year "Year"
			
	order 			region district subcounty parish hhid hh HHID wgt13 /// 	
					year season tf_hrv tf_lnd tf_yld tf_lab tf_frt ///
					tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab ///
					cp_frt cp_pst cp_hrb cp_irr 

	compress
	describe
	summarize 
	
* saving production dataset
	save		"$export/hhfinal_unps4.dta", replace


* close the log
	log	close

/* END */

