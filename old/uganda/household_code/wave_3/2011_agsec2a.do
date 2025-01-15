* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 14 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 owned plot info (2011_AGSEC2A) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* output is ready to be appended to 2011_AGSEC2B to make 2011_AGSEC2


* assumes
	* access to the raw data
	* access to cleaned GSEC2, GSEC4, and GSEC1
	* mdesc.ado

* TO DO:
	* done

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"

* close log 
	*log close
	
* open log	
	cap 					log close
	log using 				"$logout/2011_agsec2a_plt", append

	
************************************************************************
**# 1 - clean up the key variables
************************************************************************

* import wave 2 season A
	use 			"$root/2011_AGSEC2A.dta", clear
		
* unlike other waves, HHID is a numeric here
	rename 			HHID hhid
	format 			%18.0g hhid
	tostring		hhid, gen(HHID) format(%18.0g)
	
	rename			parcelID prcid
	rename 			a2aq4 prclsizeGPS
	rename 			a2aq5 prclsizeSR

	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** irrigation is q18 not q20 like in other rounds
	*** there is an error that labels the question with soil type

* clean up ownership data to make 2 ownership variables
	gen	long		pid = a2aq24a
	replace			pid = a2aq24a if pid == .
	format			%16.0g pid
	
	gen	long		pid2 = a2aq24b
	replace			pid2 = a2aq24b if pid2 == .
	format 			%16.0g pid2
	
* generate tenure variable based on fact that this is all owned plots
	gen				tenure = 1
	lab var			tenure "=1 if owned"

***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 103 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid  using "$export/2011_gsec4.dta"
	* 164 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 1,405 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2011_gsec4.dta"
	* 1,491 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	
		
************************************************************************
**# 3 - merge location data
************************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2011_gsec1"
	*** 211 unmatched from master
	*** that means 211 observations did not have location data
	*** no option at this stage except to drop all unmatched
	
	drop 		if _merge != 3	

	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	a2aq11a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2aq11a == 1 | a2aq11a == 2
	*** 431 observations deleted	

	
************************************************************************
**# 5 - clean parcel size
************************************************************************

* summarize plot size
	sum 			prclsizeGPS
	***	mean 2.18, max 75, min .01
	*** no plotsizes that are zero
	
	sum				prclsizeSR
	*** mean 2.36, max 100, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 1,585 missing, 51% of observations

* convert acres to square meters
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
	*** 0.79 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good, largest size is 30 ha
	
* gps on the larger side vs self-report
	tab				prclsize if prclsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 3 & !missing(prclsize)
	*** this is very high, 0.842, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is very low 0.127
		
* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
	*** this is terrible, 0.036, basically no relation, not unexpected
	
* summarize before imputation
	sum				prclsize
	*** mean 0.883, max 30.35, min 0.004
	
* encode district to be used in imputation
	encode admin_2, gen (admin_2dstrng) 	

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify plotsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2dstrng selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.911, max 30.35, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** strong correlation 0.854
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** none missing

	
************************************************************************
**# 4 - end matter, clean up to save
************************************************************************
					
	keep 			hhid admin_1 admin_2 admin_3 admin_4 ea sector wgt11 /// 
					prcid ea prclsize irr_any ownshp_rght_a ownshp_rght_b ///
					gender_own_a age_own_a edu_own_a gender_own_b ///
					age_own_b edu_own_b two_own tenure hh_status2011
						
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
	
	order			hhid admin_1 admin_2 admin_3 admin_4 ea sector wgt11 ///
					hh_status2011 prcid tenure prclsize
	
	compress

* save file
	save 			"$export/2011_agsec2a.dta", replace
	
* close the log
	log	close

/* END */
