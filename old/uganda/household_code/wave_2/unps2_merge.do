* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 5 Nov 2024
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
	*** matched 7,222
	*** unmatched from master 132
	drop 			if _sec4a != 3
		
* merging in labor, fertilizer, pest, manager data
	merge			m:1 hhid prcid pltid  using "$root/2010_agsec3a", generate(_sec3a)
	*** 23 unmatched from master

	drop			if _sec3a != 3
	
* merge in plot size data and irrigation data
	merge			m:1 hhid prcid using "$root/2010_agsec2", generate(_sec2)
	*** matched 6,999
	*** 200 unmatched from master

	drop			if _sec2 != 3
	*** 935 dropped
	
	isid 			hhid prcid pltid cropid 

************************************************************************
**# 2 - merge household level data in
************************************************************************

* merge in livestock data
	merge 			m:1 hhid using "$root/2010_agsec6.dta", generate(_sec6) 
	*** matched 4,884
	*** 2,155 unmatched from master
	
	drop 			if _sec6 == 2
	*** 140 dropped - want to keep households w/o livestock

* merge in household size data
	merge 			m:1 hhid using "$root/2010_gsec2h.dta", generate(_gsec2) 
	*** 0 unmatched from master
	
	drop 			if _gsec2 != 3
	*** 755 dropped
	
* merge in electricity data
	merge 			m:1 hhid using "$root/2010_gsec10.dta", generate(_gsec10) 
	*** matched 6,878
	*** 121 unmatched from master
	
	drop 			if _gsec10 != 3
	*** 835 dropped

* merge in shock data
	merge 			m:1 hhid using "$root/2010_gsec16.dta", generate(_gsec16) 
	*** matched 6,825
	*** 53 unmatched from master
	
	drop 			if _gsec16 == 2
	*** 749 dropped - want to keep households w/o shock

* merge in geovars data
	merge 			m:1 hhid using "$root/2010_geovars.dta", generate(_geovar) 
	*** 0 unmatched from master
	
	drop 			if _geovar == 2
	*** 793 dropped 
	
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
	*** mean .20, max 40
	
* plot distribution
	*kdensity		crop_area
	
* generate counting variable for number of plots in a parcel
	gen				plot_bi = 1
	
	egen			plot_cnt = sum(plot_bi), by(hhid prcid)

* generate tot plot size based on area planted
	egen			plot_tot = sum(crop_area), by(hhid prcid)
		
* replace outliers at top/bottom 5 percent
	sum 			crop_area, detail
	replace			crop_area = . if crop_area > `r(p95)' | crop_area < `r(p5)'
	* 743 changes made
	
* summarize before imputation
	sum 				crop_area, detail
	*** mean .14, sd .11, max .54, min .02
	
* destring admin_2 for imputation
	encode 		admin_2, gen(admin_2_dstrng)

* impute missing crop area
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed crop_area // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm crop_area i.admin_2_dstrng i.cropid plot_cnt prclsize, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				crop_area_1_, detail	
	*** mean .14, sd .11 max .54

* replace the imputated variable
	replace 			crop_area = crop_area_1_ 
	*** 743 changes

* plot new distribution
	*kdensity		crop_area
	
	drop				mi_miss crop_area_1_
	
	
***********************************************************************
**# 3 - impute harvest quantity
***********************************************************************
	
* summarize harvest quantity prior to imputations
	sum				harv_qty, detail
	*** mean 323, sd 1,505, max 70,000
	
* plot harvest against land
	twoway			(scatter harv_qty crop_area)
	
* one outlier
	replace			harv_qty = . if harv_qty > 70000
	
* generate temporary yield variables
	gen				yield = harv_qty/crop_area

* plot yield against land
	twoway			(scatter yield crop_area)

* replace outliers at top/bottom 5 percent
	sum 			yield, detail
	replace			harv_qty = . if yield > `r(p95)' | yield < `r(p5)'
	* 343 changes made

* impute missing harvqtykg
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed harv_qty // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm harv_qty i.admin_2_dstrng crop_area i.cropid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				harv_qty_1_, detail
	*** mean 199, sd 302, max 3,927

* replace the imputated variable
	replace 			harv_qty = harv_qty_1_
	*** 344 changes

* plot harvest against land
	twoway			(scatter harv_qty crop_area)
	
	drop 				harv_qty_1_ mi_miss
	
* generate yield variable
	replace				yield = harv_qty/crop_area
	lab var				yield "Yield (kg/ha)"
	
	sum					yield, detail
	*** mean 1,640, sd 2,199, max 55,598

	
***********************************************************************
**# 4 - impute fertilizer quantity
***********************************************************************
	
* summarize fertilizer quantity prior to imputations
	sum				fert_qty, detail
	*** mean 17, sd 36, max 200
	
* plot harvest against land
	*twoway			(scatter fert_qty crop_area)
	*** 5 data points look out of place 


* because we want to not impose on the data
* and because all these values seem plausible
* we are not imputing anyting for this wave
	
	
***********************************************************************
**# 5 - impute labor quantity
***********************************************************************
	
* summarize fertilizer quantity prior to imputations
	sum				tot_lab, detail
	*** mean 143, sd 177, max 2,300
	
* plot harvest against land
	twoway			(scatter tot_lab crop_area)	
	*** none of this looks crazy
	
* some outliers
	replace			tot_lab = . if tot_lab > 1700
	
* we did not replace outliers at top/bottom 5 percent
	sum 			tot_lab, detail

* impute missing harvqtykg
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed tot_lab // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm tot_lab i.admin_2_dstrng crop_area i.cropid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				tot_lab_1_, detail	
	replace 			tot_lab =tot_lab_1_
	


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
	replace			crop = 5 if cropid == 330 | cropid == 340 // nuts
	replace			crop = 6 if cropid > 399 & cropid < 600  // other
	replace			crop = 7 if cropid == 120 // rice
	replace			crop = 8 if cropid == 150 // sorghum
	replace			crop = 9 if cropid == 610 |cropid == 620 |cropid == 630 | ///
						cropid == 640 | cropid == 650 // tubers/root crops
	replace			crop = 10 if cropid == 111 // wheat

* attach labels
	lab define 		crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
						4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
						8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab values 		crop crop
	lab var			crop "Crop group"
	
* generate survey/wave identifiers
	gen				country = 7
	lab define 		country 1 "Ethiopia" 2 "Malawi" 3 "Mali" ///
						4 "Niger" 5 "Nigeria" 6 "Tanzania" 7 "Uganda", replace
	lab values 		country country
	lab var			country "Country"
	
	gen				survey = "UNPS 2010 - 2011"
	lab var			survey "Survey country/wave"
	
	gen				wave = 2
	lab var			wave "Survey wave"
	
	gen				year = 2010

***********************************************************************
**# 7 - harvest month
***********************************************************************

* rename variables so they match wave 4 
	rename 				ag_shck ag_shock
	rename 				hh_shck hh_shock

* in this wave seed_qty is not asked, so we kept seed value 
	
* collapse to plot-crop level
	collapse (sum)		harv_qty crop_area intrcrp seed_vle seed_type ///
						fert_qty fert_org fam_lab hrd_lab tot_lab tenure ///
						irr_any pest_any herb_any harv_miss plt_shck ///
			(mean)		harv_str_month harv_stp_month, ///
						by(pltid prcid hhid country admin_1 admin_2 ///
						admin_3 admin_4 ea survey wave year wgt10 ///
						prclsize crop ///
						ownshp_rght_a gender_own_a age_own_a edu_own_a ///
						ownshp_rght_b gender_own_b age_own_b edu_own_b two_own ///
						sector hh_size lvstck sanml pltry electric ag_shock ///
						hh_shock dist_road dist_pop aez elevat sq1 sq2 sq3 ///
						sq4 sq5 sq6 sq7 admin_2_dstrng)

* generate yield variable
	gen					yield = harv_qty/crop_area
	lab var				yield "Yield (kg/ha)"
	
	sum					yield, detail
	*** mean 1,632, sd 2,184, max 55,598

* generate average planting month for district
	*egen			plnt = mean(plnt_month), by(admin_2dstring)						

* round to nearest integer
	*replace			plnt = round(plnt,1)
	*lab var			plnt "Start of planting month"	
	
* generate average harvest month for district
	egen			harv = mean(harv_str_month), by(admin_2_dstrng)
	
* round to nearest integer
	replace			harv = round(harv,1)
	lab var			harv "Start of harvest month"					

* create "north"/"south" dummy
	gen				season = 0 if harv == 6 | harv == 7
	replace			season = 1 if season == .
	lab def			season 0 "South" 1 "North"
	lab val			season season
	lab var			season "South/North season"
	
* drop month/year
	drop			harv_str_month harv_stp_month 
	
***********************************************************************
**# 8 - end matter
***********************************************************************

* order variables
	order			pltid prcid hhid country admin_1 admin_2 ///
						admin_3 admin_4 ea survey wave year wgt10  ///
						prclsize crop season ///
						harv_qty crop_area yield intrcrp seed_vle seed_type ///
						fert_qty fert_org fam_lab hrd_lab tot_lab tenure ///
						irr_any pest_any herb_any harv_miss plt_shck ///
						ownshp_rght_a gender_own_a age_own_a edu_own_a ///
						ownshp_rght_b gender_own_b age_own_b edu_own_b two_own ///
						sector hh_size lvstck sanml pltry electric ag_shock ///
						hh_shock dist_road dist_pop aez elevat sq1 sq2 sq3 ///
						sq4 sq5 sq6 sq7							
	
	lab var				harv_qty "Harvest quantity (kg)"
	lab var				crop_area "Area planted (ha)"
	lab var				intrcrp "=1 if intercropped"
	lab var				seed_vle "Seed value (Shillings)"
	lab var				seed_type "Traditional/improved"
	lab var				fert_qty "Inorganic Fertilizer (kg)"
	lab var				fert_org "=1 if organic fertilizer used"
	lab var				fam_lab "Total family labor (days)"
	lab var				hrd_lab "Total hired labor (days)"
	lab var				tot_lab "Total labor (days)"
	lab var				tenure "=1 if owned"
	lab var				irr_any "=1 if irrigated"
	lab var				pest_any "=1 if pesticide used"
	lab var				herb_any "=1 if herbicide used"
	lab var				harv_miss "=1 if harvest qty missing"
	lab var				plt_shck	"=1 if pre-harvest shock"
						
	isid				pltid prcid hhid crop
						
	compress

* saving production dataset
	save		"$export/hhfinal_unps2.dta", replace
	

* close the log
	log	close

/* END */
