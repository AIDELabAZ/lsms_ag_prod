* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 2 Nov 24
* Edited by: rg
* Stata v.18.0, mac 

* does
	* reads Uganda wave 7 owned plot info (2018_AGSEC2A) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* output is ready to be appended to 2018_AGSEC2B to make 2018_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* stuck at imputation because 80% of plot sizes are missing in self-report

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_7/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_7"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2018_agsec2a", append

	
************************************************************************
**# 1 - clean up the key variables
************************************************************************

* import wave 7 season A
	use 			"$root/agric/AGSEC2A.dta", clear
		
* rename id variables
	rename			parcelID prcid
	rename 			s2aq4 prclsizeGPS
	rename 			s2aq5 prclsizeSR
	rename 			hhid hh_7_8
	rename 			t0_hhid hhid

	
	describe
	sort 			hh_7_8 prcid
	isid 			hh_7_8 prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** there are only 3 parcels irrigated

* clean up ownership data to make 2 ownership variables
	gen				pid = s2aq26__0
	replace			pid = s2aq24__0 if pid == .
	
	gen				pid2 = s2aq26__1
	replace			pid2 = s2aq24__1 if pid2 == .
	
* generate tenure variable based on fact that this is all owned plots
	gen				tenure = 1
	lab var			tenure "=1 if owned"
		

***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hh_7_8 pid using "$export/2018_gsec2.dta"
	* 484 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hh_7_8 pid  using "$export/2018_gsec4.dta"
	* 528 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hh_7_8 pid using "$export/2018_gsec2.dta"
	* 2,984 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hh_7_8 pid using "$export/2018_gsec4.dta"
	* 2,995 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	
	*** there are 482 observations where ownshp_rght_a and ownshp_rght_b are ///
	missing
			
************************************************************************
**# 3 - merge location data
************************************************************************	
	
* merge the location identification
	merge m:1 hh_7_8 using "$export/2018_gsec1"
	*** 4,310 matched, 58 unmatched from master
	*** 843 unmatched from using
	*** that means 843 observations did not have cultivation data
	*** 58 parcels do not have location data, so we have to drop them
	
	drop 		if _merge != 3	
	*** drops 901 observations
	
	
************************************************************************
* 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	s2aq11a 
	tab				s2aq11b
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if s2aq11a == 1 | s2aq11b == 1
	*** 1,419 observations deleted	

* verify that only parcels that did not have some annual crop on it are dropped
	tab 			s2aq11a s2aq11b
	*** zeros in every row and column other than first row/column

	
***********************************************************************
**# 4 - clean parcel size 
***********************************************************************

* summarize parcel size
	sum 			prclsizeGPS
	***	mean 1.31 max 9, min .08
	*** no plotsizes that are zero
	
	sum				prclsizeSR
	*** mean 1.79, max 150, min .1

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 2,705 missing, 94% of observations
	mdesc 			prclsizeSR
	*** 2,263 missing, 78% of observations

* convert acres to square meters
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* check correlation between the two
	corr 			prclsize selfreport
	*** 0.96 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				selfreport, detail
	drop if			selfreport == 60.7029
	
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good, but largest self-reported is 60
	
* gps on the larger side vs self-report
	tab				prclsize if prclsize > 3, plot
	*** no GPS plot is greater than 3

* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 2 & !missing(prclsize)
* twoway (scatter prclsize selfreport if prclsize > 3 & !missing(prclsize))
	*** this is high, 0.697, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** this is not great 0.422
		
* summarize before imputation
	sum				prclsize
	*** mean 0.52, max 3.6, min 0.03
	

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed prclsize // identify plotsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hh_7_8 prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm prclsize i.admin_2 selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			prclsize_1_
	*** mean 0.884, max 30.35, min 0.004
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** strong correlation 0.824
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize


	
************************************************************************
**# 5 - end matter, clean up to save
************************************************************************
	
	keep 			hhid hh_7_8  admin_1 admin_2 admin_3 ///
					admin_4 sector year wgt18  prcid  ///
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

	isid			hh_7_8 prcid
	
	order			hh_7_8	hhid  admin_1 admin_2 admin_3 ///
					admin_4  sector year wgt18  prcid ///
					tenure prclsize
	
	compress


* save file
	save 			"$export/2018_agsec2a.dta", replace

* close the log
	log	close

/* END */
