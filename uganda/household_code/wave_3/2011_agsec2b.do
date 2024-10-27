* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 25 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 rented plot info (2011_AGSEC2B) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* appends to 2011_AGSEC2A to output 2013_AGSEC2

* assumes
	* access to the raw data
	* access to cleaned GSEC2, GSEC4, AGSEC1, AGSEC2A
	* mdesc.ado

* TO DO:
	* done

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2011_agsec2b_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 3 season A
	use 			"$root/2011_AGSEC2B.dta", clear

* unlike other waves, HHID is a numeric here
	rename 			HHID hhid
	rename			parcelID prcid
	rename 			a2bq4 prclsizeGPS
	rename 			a2bq5 prclsizeSR
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq16 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"

* questions 21a and 21b ask about ownership
	rename 			a2bq21a pid
	rename			a2bq21b pid2 

* generate tenure variable based on fact that this is all rented prcls
	gen				tenure = 0
	lab var			tenure "=1 if owned"

***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 28 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2011_gsec4.dta"
	* 43 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	rename 			member_number member_number_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 392 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2011_gsec4.dta"
	* 418 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b
	rename 			member_number member_number_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	
	
***********************************************************************
**# 3 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2011_gsec1"
	*** merged 994, 2,049 unmerged total, only 83 from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	a2bq12a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12a == 2
	*** 133 observations deleted	

	
***********************************************************************
**# 5 - clean prclsize
***********************************************************************

* summarize parcel size
	sum 			prclsizeGPS
	***	mean 1.23, max 12.2, min .07
	
	sum				prclsizeSR
	*** mean 1.1, max 12, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 732 missing, 85.02% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* examine gps outlier values
	sum				prclsize, detail
	*** mean 0.50, min 0.02, max 4.93, std. dev. .60
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.44, min 0.004, max4.85, std. dev. .45
	*** the self-reported 10 ha is large but not unreasonable	
	
* check correlation between the two
	corr 			prclsize selfreport
	*** 0.90 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is very low 0.03

* encode district to be used in imputation
	encode 			admin_2, gen (admin_2dstrng) 	

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
	*** mean 0.55, max 4.9, min .02
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** so-so correlation, 0.58
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** none missing

***********************************************************************
**# 6 - appends sec2a
***********************************************************************
	
* keep only necessary variables					
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

* append owned plots
	append			using "$export/2011_agsec2a.dta"
	
					
***********************************************************************
**# 7 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid
	compress
	describe
	summarize

* save file
	save 			"$export/2011_agsec2.dta", replace

* close the log
	log	close

/* END */
