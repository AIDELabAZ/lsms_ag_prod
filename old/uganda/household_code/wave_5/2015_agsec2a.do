* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 8 Nov 2024
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 5 owned plot info (2015_AGSEC2A) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* output is ready to be appended to 2015_AGSEC2B to make 2015_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* done

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_5/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2015_agsec2a_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/agric/AGSEC2A.dta", clear
		
	rename			HHID hhid
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
	*** there are 39 observations irrigated

* clean up ownership data to make 2 ownership variables
	gen	long		pid = a2aq26a
	replace			pid = a2aq24a if pid == .
	
	gen	long		pid2 = a2aq26b
	replace			pid2 = a2aq24b if pid2 == .
	
* generate tenure variable based on fact that this is all owned plots
	gen				tenure = 1
	lab var			tenure "=1 if owned"

***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2015_gsec2.dta"
	* 161 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid  using "$export/2015_gsec4.dta"
	* 175 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2015_gsec2.dta"
	* 1,859 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2015_gsec4.dta"
	* 1,880 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_b
	rename			gender gender_own_b
	rename			age age_own_b
	rename			edu edu_own_b

* generate a variable reflecting two owners
	gen 			two_own = 1 if ownshp_rght_a != . & ownshp_rght_b != .
	replace 		two_own = 0 if two_own==.	
	
		

***********************************************************************
**# 3 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2015_gsec1"
	*** merged 4,129, 1,128 unmerged total, 1,057 from using data
	*** 71 unmerged from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 4 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** even data label says first season is a2aq11b, by looking at previous waves and the documentation, we can say that a2aq11a is the first cropping season
	tab 		 	a2aq11a
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2aq11a == 1 | a2aq11a == 2
	*** 636 observations deleted	

	
***********************************************************************
**# 4 - clean parcel size
***********************************************************************

* summarize parce size
	sum 			prclsizeGPS
	***	mean 1.56, max 158, min 0
	*** only 1 plotsize = 0
	
	sum				prclsizeSR
	*** mean 1.51, max 300, min .01

* how many missing values are there?
	mdesc 			prclsizeGPS
	*** 2,141 missing, 61.2% of observations

* convert acres to hectares
	gen				prclsize = prclsizeGPS*0.404686
	label var       prclsize "Parcel size (ha)"
	
	gen				selfreport = prclsizeSR*0.404686
	label var       selfreport "Parcel size (ha)"

* examine gps outlier values
	sum				prclsize, detail
	*** mean 0.63, min 0, max 63.94, std. dev. 1.88
	
	sum				prclsize if prclsize < 60, detail
	*** mean 0.585, max 9.3, min 0, std. dev 0.75
	
	list			prclsize selfreport if prclsize > 60 & !missing(prclsize)
	*** gps plotsize is a hundred times larger self reported, which means a decimal point misplacement.
	
* recode outlier to be 1/100
	replace			prclsize = prclsize/100 if prclsize > 60
	
	sum 			selfreport, detail
	*** mean 0.61, max 121, min 0.004
	
	sum				selfreport if selfreport < 60, detail
	*** mean 0.576, max 20.2, min 0.004
	
	list			prclsize selfreport if selfreport > 60 & !missing(selfreport)
	*** self reported value of 121 hectares seems unreasonable.
	*** prclsize value is missing for this observation.
	** dividing by a 100 makes it a more reasonable plotsize
	
	replace 		selfreport = selfreport/100 if selfreport > 60 & prclsize == . 
	
* check correlation between the two
	corr 			prclsize selfreport
	*** 0.88 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				prclsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			prclsize selfreport if !inrange(prclsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(prclsize)
	*** these all look good, largest size is 9 ha
	
* gps on the larger side vs self-report
	tab				prclsize if prclsize > 3, plot
	*** distribution looks reasonable

* correlation for larger plots	
	corr			prclsize selfreport if prclsize > 3 & !missing(prclsize)
	*** this is very high, 0.83, so these look good

* correlation for smaller plots	
	corr			prclsize selfreport if prclsize < .1 & !missing(prclsize)
	*** correlation is negative, -0.108
		
* correlation for extremely small plots	
	corr			prclsize selfreport if prclsize < .01 & !missing(prclsize)
	*** correlation is negative, -0.728
	
* summarize before imputation
	sum				prclsize
	*** mean 0.585, max 9.3, min 0	

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
	*** mean 0.59, max 9.3, min 0
	
	corr 			prclsize_1_ selfreport if prclsize == .
	*** strong correlation, 0.81
	
	replace 		prclsize = prclsize_1_ if prclsize == .
	
	drop			mi_miss prclsize_1_
	
	mdesc 			prclsize
	*** none missing

	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid hh hh_agric prcid admin_?  wgt15 hwgt_W4_W5 ///
					prclsize irr_any ea rotate ownshp_rght_a ownshp_rght_b ///
						gender_own_a age_own_a edu_own_a gender_own_b ///
						age_own_b edu_own_b two_own tenure sector

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
	
	order			hhid hh_agric rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector wgt15 hwgt_W4_W5 prcid ///
						tenure prclsize	
	
	compress
	describe
	summarize

* save file
	save 			"$export/2015_agsec2a.dta", replace

* close the log
	log	close

/* END */
