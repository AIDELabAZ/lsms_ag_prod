* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 rented plot info (2010_AGSEC2B) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* appends to 2010_AGSEC2A to output 2010_AGSEC2

* assumes
	* access to all raw data
	* access to cleand GSEC1, GSEC 2, and GSEC4, AGSEC2A
	* mdesc.ado

* TO DO:
	* done

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2010_agsec2b_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/2010_AGSEC2B.dta", clear
		
	rename			HHID hhid
	rename 			a2bq4 prclsizeGPS
	rename 			a2bq5 prclsizeSR
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq19 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"

* clean up ownership data to make 2 ownership variables

	gen				member_number = a2bq24a
	
	gen 			member_number2 = a2bq24b
	
	count if		member_number==. & member_number2 ==.
	*** there are 43 missing both member number 
	
	
* generate tenure variables based on the fact that this is all rented parcels
	gen				tenure = 0 
	lab var 		tenure "=1 if owned"

***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid member_number using "$export/2010_gsec2.dta"
	* 20 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid member_number using "$export/2010_gsec4.dta"
	* 103 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			member_number member_number_a
	* or rename 	member_number ownshp_rght_a (?)
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename pid for b to just pid so we can merge	
	rename			member_number2 member_number

* merge in age and gender for owner b
	merge m:1 		hhid member_number using "$export/2010_gsec2.dta"
	* 452 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid member_number using "$export/2010_gsec4.dta"
	* 502 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			member_number member_number_b
	* or rename 	member_number ownshp_rght_b (?)
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
		
	
	
***********************************************************************
**# 3 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2010_gsec1"
	*** merged 1,052 1,910 unmerged total, only 11 from master
	*** drop all unmatched since no land area data
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	a2bq15a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq15a == 1 | a2bq15a == 2
	*** 146 observations deleted	

	
***********************************************************************
**# 5 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			prclsizeGPS
	***	mean 1.27, max 29, min .08
	
	sum				prclsizeSR
	*** mean 1.14, max 50, min .1

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 648 missing, 71.5% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* examine gps outlier values
	sum				prclsize, detail
	*** mean 0.51, min 0.03 max 11.7, std. dev. .93
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.46, min 0.04, max 20.23, std. dev. 0.85
	*** the self-reported 10 ha is large but not unreasonable	
	
* examine outliers
	list 			prclsize selfreport if prclsize > 10 & !missing(prclsize)

* recode outlier
	replace 		selfreport = selfreport*100 if prclsize > 10 & !missing(prclsize)
	*** plotsize looks to be 100 times larger than self reported
* check correlation between the two
	corr 			prclsize selfreport
	*** 0.95 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** correlation is negative, -0.15

* encode district to be used in imputation
	encode 			admin_2, gen (admin_2dstrng) 

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify prclsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2dstrng selfreport, add(1) rseed(245780) /// 
	noisily dots force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.45, max 11.7, min .003
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** so-so correlation, 0.57
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** 8 missing
	** 8 observations are missing self report and plotsizeGPS
	
* drop observations
	drop 			if prclsize == .

***********************************************************************
**# 5 - appends sec2a
***********************************************************************
	
	
* keep only necessary variables
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

* append owned plots
	append			using "$export/2010_agsec2a.dta"
					
***********************************************************************
**# 6 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid
	compress
	describe
	summarize

* save file
	save 			"$export/2010_agsec2.dta", replace

* close the log
	log	close

/* END */
