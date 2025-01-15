* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 owned plot info (2019_AGSEC2A) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* output is ready to be appended to 2019_AGSEC2B to make 2019_AGSEC2

* assumes
	* access to the raw data
	* access to cleaned GSEC2, GSEC4, and AGSEC1
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
	log using 			"$logout/2019_agsec2a", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 8 season A
	use 			"$root/agric/agsec2a.dta", clear
			
* Rename ID variables
	rename			parcelID prcid
	rename 			s2aq4 prclsizeGPS
	rename 			s2aq5 prclsizeSR
	recast 			str32 hhid
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** irrigation is q18 not q20 like in other rounds

* clean up ownership data to make 2 ownership variables
	gen	long		pid = s2aq26__0
	replace			pid = s2aq24__0 if pid == .
	
	gen	long		pid2 = s2aq26__1
	replace			pid2 = s2aq24__1 if pid2 == .
	*** there are 80 observations missing both pid
	
* generate tenure variable based on fact that this is all owned plots
	gen				tenure = 1
	lab var			tenure "=1 if owned"
	
	
***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2019_gsec2.dta"
	* 80 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid  using "$export/2019_gsec4.dta"
	* 88 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2019_gsec2.dta"
	* 2,538 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2019_gsec4.dta"
	* 2,540 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	
	
***********************************************************************
**#3 - merge location data
***********************************************************************	

 * merge the location identification
	merge m:1 hhid using "$export/2019_gsec1"	
	*** 4,085 matched including all from master
	*** 874 unmatched from using
	
	drop 		if _merge != 3	
	drop 		_merge
	*** 876 observations deleted
	
	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	s2aq11a 
	tab				s2aq11b
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if s2aq11a == 1 | s2aq11b == 1
	*** 1,453 observations deleted

* verify that only parcels that did not have some annual crop on it are dropped
	tab 			s2aq11a s2aq11b
	*** zeros in every row and column other than first row/column
	
	
***********************************************************************
**#4 - clean parcel size
***********************************************************************

* summarize plot size
	sum 			prclsizeGPS
	***	mean 1.57, max 21.6, min .01
	*** no plotsizes that are zero
	
	sum				prclsizeSR
	*** mean 1.61, max 50, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 1,565 missing, 56.61% of observations
	mdesc 			prclsizeSR
	*** 10 missing, 0.38% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
* twoway (scatter plotsize selfreport)
	*** 0.97 correlation, high correlation between GPS and self reported
	
* Look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good, largest size is 8.037 ha
	
* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 3 & !missing(prclsize)
* twoway (scatter plotsize selfreport if plotsize > 3 & !missing(plotsize))
	*** this is very high, 0.98, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
* twoway (scatter plotsize selfreport if plotsize < .1 & !missing(plotsize))
	*** this is sort of in the middle, positive but less strong correlation at 0.52 
		
* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
* twoway (scatter plotsize selfreport if plotsize < .01 & !missing(plotsize))
	*** only 2 plots this small
	
* summarize before imputation
	sum				prclsize
	*** mean 0.64, max 8.74, min 0.004
	
	
* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify plotsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2 selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.66, max 8.74, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** strong correlation 0.89
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** 10 missing, 0.38%

	drop if			prclsize == .
	
***********************************************************************
**#4 - end matter, clean up to save
***********************************************************************
	rename			hh hhid_7_8

	keep 			hhid hhid_7_8 admin_1 admin_2 admin_3 ///
					admin_4 sector year wgt19 prclsize irr_any /// 
					ownshp_rght_a ownshp_rght_b prcid ///
					gender_own_a age_own_a edu_own_a gender_own_b ///
					age_own_b edu_own_b two_own tenure
						
	lab var			ownshp_rght_a "pid for first owner"
	lab var			ownshp_rght_b "pid for second owner"	
	lab var			gender_own_a "Gender of first owner"
	lab var			age_own_a "Age of first owner"
	lab var			edu_own_a "=1 if first owner has formal edu"
	lab var			gender_own_b "Gender of second owner"	
	lab var			age_own_b "Age of second owner"
	lab var			edu_own_b "=1 if first owner has formal edu"
	lab var			two_own "=1 if there is joint ownership"
	lab var			prcid "Parcel ID"

	isid			hhid prcid
	
	order			hhid hhid_7_8 admin_1 admin_2 admin_3 ///
						admin_4 sector year wgt19 prcid ///
						tenure prclsize
	
	compress


* save file
	save 			"$export/2019_agsec2a.dta", replace

* close the log
	log	close

/* END */
