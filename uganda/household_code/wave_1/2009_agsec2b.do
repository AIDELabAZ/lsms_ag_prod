* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 1 owned plot info (2009_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2010_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* appends to 2009_AGSEC2A to output 2013_AGSEC2

* assumes
	* access to all raw data
	* access to cleand GSEC1, GSEC 2, and GSEC4, AGSEC2A
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
	cap 				log close
	log using 			"$logout/2009_agsec2b_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 1 season A
	use 			"$root/2009_AGSEC2B.dta", clear
		
	rename 			Hhid hhid
	rename 			A2bq2 prcid
	rename 			A2bq4 prclsizeGPS
	rename 			A2bq5 prclsizeSR

	
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if A2bq19 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** there are 16 observations irrigated
	
* clean up ownership data to make 2 ownership variables

	gen				member_number = A2bq24a
	
	gen 			member_number2 = A2bq24b
	
	count if		member_number==. & member_number2 ==.
	*** there are 43 missing both member number 
	
	
* generate tenure variables based on the fact that this is all owned plots
	gen				tenure = 1 
	lab var 		tenure "=1 if owned"


***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	
	
* merge the location identification
	merge m:1 		hhid member_number using "$export/2009_gsec2"
	*** 51 unmatched from master
	
	drop 			if _merge ==2 
	drop			_merge

* merge in education for owner a 
	merge m:1 		hhid member_number using "$export/2009_gsec4"	
	** 138 unmatched from master 
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
	** 834 unmatched from master
	
	drop 			if _merge ==2 
	drop 			_merge
	
* merge in education for owner b 
	merge m:1 		hhid member_number using "$export/2009_gsec4"
	* 878 unmatched from master 
	
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

* merge hh key 
	merge m:1 		hhid using "$export/2009_GSEC1"
	*** merged 1,513, 1,996 unmerged in using data
	*** drop all unmatched since no land area data
	
	drop 		if _merge != 3	
	drop		_merge

************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	A2bq15a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if A2bq15a == 1 | A2bq15a == 2
	*** 322 observations deleted	

	
***********************************************************************
**# 5 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			prclsizeGPS
	***	mean .72, max 80.9, min 0
	
	sum				prclsizeSR
	*** mean 1.02, max 25, min 0

* replace plot size = 0 with missing for imputation
	replace			prclsizeGPS = . if prclsizeGPS == 0
	replace			prclsizeSR = . if prclsizeSR == 0
	
* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 769 missing, 64.5% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* examine gps outlier values
	sum				prclsize, detail
	*** mean 0.43, min 0, max 32.7, std. dev. 1.63
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.41, min 0, max 10.11, std. dev. .539
	*** the self-reported 10 ha is large but not unreasonable	
	
* check correlation between the two
	corr 			prclsize selfreport
	*** 0.60 correlation, weak correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
* divide outlier by 10
	replace			prclsize = prclsize/10 if prclsize > 30

* replace outlier as missing values
	replace 		selfreport = . if selfreport > 9						
							
* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** correlation is negative, -0.16
	
* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 1 & !missing(prclsize)
	*** this is pretty high, 0.40, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is terrible, correlation is -0.16

* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
	*** this is terrible, -0.38, correlation is basically zero

* summarize before imputation
	sum				prclsize
	*** mean 0.36, max 4.1, min 0.004
	
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
	*** mean 0.37, max 4.11, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** so-so correlation, 0.66
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** two missing, both plotsize and selfreport values are missing
	
* drop observation
	drop			if prclsize ==.
	
* correlation plotsize vs selfreport
	corr 			prclsize selfreport
	*** correlation 0.64
	
***********************************************************************
**# 6 - appends sec2a
***********************************************************************
	
* keep only necessary variables
	rename 			Year year
	
	keep 			hhid prcid admin_1 admin_2 admin_3 admin_4 ///
					sector year wgt09wosplits wgt09 hh_status2009 ///
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
	
	order			hhid hh_status2009 admin_1 admin_2 admin_3 ///
						admin_4 sector year wgt09 wgt09wosplits prcid ///
						tenure prclsize

	compress
	describe
	summarize
	
* append owned plots
	append			using "$export/2009_agsec2a.dta"
	erase 			"$export/2009_agsec2a.dta"
	
* drop duplicate
	duplicates 		drop hhid prcid, force
	** no duplicates
					
***********************************************************************
**# 7 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid
	compress
	describe
	summarize

* save file
	save 			"$export/2009_agsec2.dta", replace

* close the log
	log	close

/* END */
