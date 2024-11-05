* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 rented plot info (2019_AGSEC2B) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* appends to 2019_AGSEC2A to output 2019_AGSEC2

* assumes
	* access to the raw data
	* access to cleaned GSEC2, GSEC4, GSEC1, AGSEC2A
	* mdesc.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2019_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec2b.dta", clear

* Rename ID variables
	rename			parcelID prcid
	rename 			s2aq04 prclsizeGPS
	rename 			s2aq05 prclsizeSR
	recast 			str32 hhid
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** irrigation is q18 not q20 like in other rounds
	
* generate tenure variable based on fact that this is all owned plots
	gen				tenure = 0
	lab var			tenure "=1 if owned"
	
***********************************************************************
**#3 - merge location data
***********************************************************************	

 * merge the location identification
	merge m:1 hhid using "$export/2019_gsec1"	
	*** unmatched from master 2
	
	drop 		if _merge != 3	
	drop 		_merge
	*** 2,187 observations deleted
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	a2bq12a 
	tab				a2bq12b
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12b == 1
	*** 218 observations deleted	

	
***********************************************************************
**# 4 - clean parcel size
***********************************************************************

* summarize parcel size
	sum 			prclsizeGPS
	***	mean .90, max 4.17, min .06
	
	sum				prclsizeSR
	*** mean .96, max 10, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 980 missing, 93% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
* twoway (scatter prclsize selfreport)
	*** 0.972correlation, high correlation between GPS and self reported
	
* Look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good, largest size is 1.68 ha
	
* summarize before imputation
	sum				prclsize
	*** mean 0.367, max 1.68, min 0.024
	

* impute missing parcel sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify plotsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2 selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.34, max 1.68, min 0.024
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** strong correlation 0.83
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** 5 missing, 0.47%

	drop if			prclsize == .
	
***********************************************************************
**#4 - end matter, clean up to save
***********************************************************************

	rename			hh hhid_7_8

	keep 			hhid hhid_7_8 admin_1 admin_2 admin_3 ///
					admin_4 sector year wgt19 prclsize irr_any /// 
					prcid tenure
						
	lab var			prcid "Parcel ID"

	isid			hhid prcid
	
	order			hhid hhid_7_8 admin_1 admin_2 admin_3 ///
						admin_4 sector year wgt19 prcid ///
						tenure prclsize
	compress
	describe
	summarize

* save file
	save 			"$export/2019_agsec2b.dta", replace

* append 2a to build complete plot data setup
	append			using "$export/2019_agsec2a.dta"

	compress
	describe
	summarize

* save file
	save 			"$export/2019_agsec2.dta", replace
	
* close the log
	log	close

/* END */
