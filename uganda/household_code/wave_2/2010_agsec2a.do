* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 owned plot info (2010_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2010_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* cleans
		* parcel sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* ready to be appended to 2010_AGSEC2B

* assumes
	* access to all raw data
	* access to cleand GSEC1, GSEC 2, and GSEC4
	* mdesc.ado

* TO DO:
	* done

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"

* close log 
	*log close
	
* open log	
	cap 					log close
	log using 				"$logout/2010_agsec2a_plt", append

	
************************************************************************
**# 1 - clean up the key variables
************************************************************************

* import wave 2 season A
	use 			"$root/2010_AGSEC2A.dta", clear

	rename 			HHID hhid
	rename 			a2aq4 prclsizeGPS
	rename 			a2aq5 prclsizeSR
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid
	
* make a variable that shows the irrigation
	gen irr_any = 1 if a2aq20 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"

* clean up ownership data to make 2 ownership variables

	gen				member_number = a2aq26a
	
	gen 			member_number2 = a2aq26b
	
	count if		member_number==. & member_number2 ==.
	*** there 19 missing both member number 
	
	
* generate tenure variables based on the fact that this is all owned plots
	gen				tenure = 1 
	lab var 		tenure "=1 if owned"
	
***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	
	
* merge the location identification
	merge m:1 		hhid member_number using "$export/2010_gsec2"
	*** 28 unmatched from master
	
	drop 			if _merge ==2 
	drop			_merge

* merge in education for owner a 
	merge m:1 		hhid member_number using "$export/2010_gsec4"	
	** 210 unmatched from master 
	drop 			if _merge ==2 
	drop 			_merge

	rename 			pid ownshp_rght_a
	rename			member_number member_number_a
	* or rename 	member_number ownshp_rght_a (?)
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a

* rename member_number2 so we can merge 
	rename 			member_number2 member_number
	
* merge in age and gende for owner b 
	merge m:1 		hhid member_number using "$export/2010_gsec2"
	** 1,446 unmatched from master
	
	drop 			if _merge ==2 
	drop 			_merge
	
* merge in education for owner b 
	merge m:1 		hhid member_number using "$export/2010_gsec4"
	* 1,604 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			member_number member_number_b
	* or rename 	member_number ownshp_rght_b (?)
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b
	
* create variable for two owners
	gen 			two_own = 1 if ownshp_rght_a !=. & ownshp_rght_b !=.
	replace 		two_own = 0 if two_own ==.
		
	
************************************************************************
**# 3 - merge location data
************************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2010_gsec1.dta"
	*** 10 unmatched from master
	*** that means 10 observations did not have location data
	*** no option at this stage except to drop all unmatched
	
	drop 		if _merge != 3
	
	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	a2aq13a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2aq13a == 1 | a2aq13a == 2
	*** 248 observations deleted
	
	
************************************************************************
**# 5 - clean parcel size
************************************************************************

* summarize parcel size
	sum 			prclsizeGPS
	***	mean 3.72, max 676, min .01
	*** no plotsizes that are zero
	
	sum				prclsizeSR
	*** mean 2.18, max 100, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 1,073 missing, 34% of observations
	
* convert acres to square meters
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
	*** 0.25 correlation, reasonably good between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** values over 100 are clearly wrong
	*** the ones in the 70s I am unsure about
	*** the ones in the 30s and 40s look okay

	replace			prclsize = . if prclsize > 40
	*** 9 change made

* gps on the larger side vs self-report
	tab				prclsize if prclsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 3 & !missing(prclsize)
	*** this is really low, 0.154, compared to 2009 which was 0.616

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is basically the same, 0.174
		
* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
	*** this is higher, but negative, -0.403, which is strange in itself
	
* summarize before imputation
	sum				prclsize
	*** mean 0.956, max 35.29, min 0.004
	
* encode district to be used in imputation
	encode 			admin_2, gen (admin_2dstrng) 	

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify plotsize_GPS as the variable being imputed
	sort		admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2dstrng selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
	
* how did imputing go?
	sum 			prclsize_1_
	*** mean 1.05, max 35.29, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** 0.4857 ok correlation
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	

	mdesc 			prclsize
	*** none missing
	
	drop 			if prclsize ==.
	
************************************************************************
**# 4 - end matter, clean up to save
************************************************************************


	keep 			hhid prcid admin_1 admin_2 admin_3 admin_4 ///
					sector spitoff09_10 spitoff10_11 wgt10 hh_status2010 ///
					prclsize irr_any ownshp_rght_a ownshp_rght_b ///
					member_number_a member_number_b ///
					gender_own_a age_own_a edu_own_a gender_own_b ///
					age_own_b edu_own_b two_own tenure ea
					
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
	lab var 		member_number_a "member number first owner"
	lab var 		member_number_b "member number second owner"

	isid			hhid prcid
	
	order			hhid hh_status2010 admin_1 admin_2 admin_3 ///
						admin_4 sector wgt10  prcid ///
						tenure prclsize

	compress
	describe
	summarize

* save file		
	save 			"$export/2010_agsec2a.dta", replace

* close the log
	log	close

/* END */
