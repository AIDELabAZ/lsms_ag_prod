* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 rented plot info (2013_AGSEC2B) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* appends to 2013_AGSEC2A to output 2013_AGSEC2

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
	global root 	"$data/raw_lsms_data/uganda/wave_4/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"

* open log	
	cap 				log close
	log using 			"$logout/2013_agsec2b_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 4 season A rented plots
	use 			"$root/agric/AGSEC2B.dta", clear
		
* order and rename variables
	order			hh
	drop			wgt_X

	rename			hh hhid
	rename			HHID hh
	rename			parcelID prcid
	rename 			a2bq4 prclsizeGPS
	rename 			a2bq5 prclsizeSR
	
	isid 			hh prcid
	isid			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq16 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "=1 if irrigated"
	*** there are 8 irrigated	

* clean up ownership data to make 2 ownership variables
	gen	long		pid = a2bq21a	
	gen	long		pid2 = a2bq21b

* generate tenure variable based on fact that this is all rented prcls
	gen				tenure = 0
	lab var			tenure "=1 if owned"
	
***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 11 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 12 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 421 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 422 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	

***********************************************************************
**# 3 - merge location data
***********************************************************************	
		
* merge household key 
	merge m:1 hhid using "$export/2013_agsec1"		
	*** merged 1,294, 1,603 unmerged in using data
	*** drop all unmatched since no land area data
	
	drop 		if _merge != 3	
	drop		_merge
	
	
***********************************************************************
**# 4 - keeping cultivated land
***********************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11a
	tab 		 	a2bq12a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12a == 2
	*** 231 observations deleted	

	
***********************************************************************
**# 5 - clean prclsize
***********************************************************************

* summarize plot size
	sum 			prclsizeGPS
	***	mean 1.06, max 16.8, min .07
	
	sum				prclsizeSR
	*** mean .97, max 25, min .1

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 822 missing, 87% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* examine gps outlier values
	sum				prclsize, detail
	*** mean 0.43, min 0.02, max 6.79, std. dev. .66
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.39, min 0.04, max 10.11, std. dev. .53
	
* check correlation between the two
	corr 			prclsize selfreport
	*** 0.96 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good

* summarize before imputation
	sum				prclsize
	*** mean 0.41, min 0.02, max 6.79

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify prclsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2 selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.38, max 6.8, min .02
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** high correlatio, 0.72
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** none missing

	
***********************************************************************
**# 6 - appends agsec2a
***********************************************************************

	keep 			hhid hh hhid_pnl rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector year wgt13 wgt_pnl prcid ea ///
						prclsize irr_any ownshp_rght_a ownshp_rght_b ///
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

* append owned plots
	append			using "$export/2013_agsec2a.dta"
	
	erase			"$export/2013_agsec2a.dta"
	
* drop duplicate
	duplicates 		drop hhid prcid, force
	* 0 deleted
					
***********************************************************************
**# 7 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid

	order			hhid hh hhid_pnl rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector year wgt13 wgt_pnl prcid ///
						tenure prclsize
	
	compress

* save file
	save 			"$export/2013_agsec2.dta", replace

* close the log
	log	close

/* END */
