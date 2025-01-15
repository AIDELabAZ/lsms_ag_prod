* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 8 Nov 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 1 owned plot info (2009_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2010_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* cleans
		* parcel sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* ready to be appended to 2009_AGSEC2B

* assumes
	* access to all raw data
	* access to cleand GSEC1, GSEC 2, and GSEC4
	* mdesc.ado

* TO DO:
	*	done
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"

	
* open log	
	cap 					log close
	log using 				"$logout/2009_agsec2a", append

	
**********************************************************************************
**# 1	- clean up the key variables
**********************************************************************************

	use 			"$root/2009_AGSEC2A", clear

	rename 			Hhid hhid
	rename 			A2aq2 prcid
	rename 			A2aq4 prclsizeGPS
	rename 			A2aq5 prclsizeSR

	
	sort 			hhid prcid
	isid 			hhid prcid
	
* make a variable that shows the irrigation
	gen				irr_any = 1 if A2aq20 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"

* clean up ownership data to make 2 ownership variables

	gen				member_number = A2aq26a
	
	gen 			member_number2 = A2aq26b
	
	count if		member_number==. & member_number2 ==.
	*** there are 126 missing both member number 
	
	
* generate tenure variables based on the fact that this is all owned plots
	gen				tenure = 1 
	lab var 		tenure "=1 if owned"


***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	
	
* merge the location identification
	merge m:1 		hhid member_number using "$export/2009_gsec2"
	*** 134 unmatched from master
	
	drop 			if _merge ==2 
	drop			_merge

* merge in education for owner a 
	merge m:1 		hhid member_number using "$export/2009_gsec4"	
	** 283 unmatched from master 
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
	merge m:1 		hhid member_number using "$export/2009_gsec2"
	** 2,174 unmatched from master
	
	drop 			if _merge ==2 
	drop 			_merge
	
* merge in education for owner b 
	merge m:1 		hhid member_number using "$export/2009_gsec4"
	* 2,276 unmatched from master 
	
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
	
	
**********************************************************************
**# 3 - merge location data 
**********************************************************************		
	
* merge hh key 
	merge m:1 		hhid using "$export/2009_GSEC1"
	*** merge 4,302
	*** unmatched from master , from using 838
	*** drop all unmatched since no land area
	
	drop 			if _merge !=3
	drop 			_merge
	
	
**********************************************************************
**# 4 - keeping cultivated land
**********************************************************************	

* what was the primary use of the parcel
	tab 		 	A2aq13a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if A2aq13a == 1 | A2aq13a == 2
	*** 849 observations deleted
	
	
***********************************************************************
**# 5 - clean parcel size
***********************************************************************

* summarize parcel size
	sum 			prclsizeGPS
	***	mean 2.45, max 810, min 0
	*** plot size of zero looks to be a mistake
	
	sum				prclsizeSR
	*** mean 2.27, max 250, min 0
	
* replace plot size = 0 with missing for imputation
	replace			prclsizeGPS = . if prclsizeGPS == 0
	replace			prclsizeSR = . if prclsizeSR == 0
	*** 52 changes made in plotsizeGPS, 5 plotsizeSR

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 998 missing, 29% of observations
	
* convert acres to square meters
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
	*** 0.186 correlation, low correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** obs. 861 appear to be incorrect GPS value, as the self-report is nowhere close
	*** obs. 2031 appears to be correct GPS value, as self-reported is close
	
	replace			prclsize = . if prclsize > 300
	*** 1 change made

* gps on the larger side vs self-report
	tab				prclsize if prclsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 3 & !missing(prclsize)
	*** this is pretty high, 0.616, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is terrible, correlation is -0.042, bassically zero relatinship
		
* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
	*** this is actually pretty good, 0.212, which is strange in itself
	
* summarize before imputation
	sum				prclsize
	*** mean 0.880, max 25.80, min 0.004
	
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
	*** mean 0.95, max 25.80, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** 0.578 better correlation
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	

	mdesc 			prclsize
	*** both gps and self reported missing for 1 observation
	
	drop 			if prclsize ==.
	
	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	rename 			Year year
	
	keep 			hhid prcid admin_1 admin_2 admin_3 admin_4 ///
					sector year wgt09wosplits wgt09 hh_status2009 ///
					prclsize irr_any ownshp_rght_a ownshp_rght_b ///
					member_number_a member_number_b ///
					gender_own_a age_own_a edu_own_a gender_own_b ///
					age_own_b edu_own_b two_own tenure ea county
					
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
	
	order			hhid hh_status2009 admin_1 admin_2 admin_3 ///
						admin_4 sector year wgt09 wgt09wosplits prcid ///
						tenure prclsize

	compress
	describe
	summarize

* save file		
	save 			"$export/2009_agsec2a.dta", replace


* close the log
	log	close

/* END */	
