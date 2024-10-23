* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 owned plot info (2013_AGSEC2A) for the 1st season
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
		* tenure
		* irrigation
		* plot ownership
	* merge in owner characteristics from gsec2 gsec4
	* output is ready to be appended to 2013_AGSEC2B to make 2013_AGSEC2

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
	global root 	"$data/raw_lsms_data/uganda/wave_4/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_4"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2013_agsec2a_plt", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 4 season A owned plots
	use 			"$root/agric/AGSEC2A.dta", clear
		
* order and rename variables
	order			hh
	drop			wgt_X

	rename			hh hhid
	rename			HHID hh
	rename			parcelID prcid
	rename 			a2aq4 plotsizeGPS
	rename 			a2aq5 plotsizeSR
	
	isid 			hh prcid
	isid			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "=1 if irrigated"
	*** there are 26 irrigated	
	
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
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 38 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid  using "$export/2013_gsec4.dta"
	* 38 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 1,424 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 1,434 unmatched from master 
	
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
	*** merged 4,142, 345 unmerged in using data
	*** drop all unmatched since no land area data
	
	drop 		if _merge != 3	
	drop		_merge
	
	
***********************************************************************
**# 4 - keeping cultivated land
***********************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	a2aq11a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual crops
	
	keep			if a2aq11a == 1 | a2aq11a == 2
	*** 507 observations deleted	

	
***********************************************************************
**# 5 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.49, max 48, min .01
	*** no plotsizes that are zero
	
	sum				plotsizeSR
	*** mean 1.48, max 40, min .02

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 1,906 missing, 53% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var		plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum 			plotsize, detail
	*** mean 0.60, max 19.42, min 0.004, std. dev. 1.03
	
	sum 			plotsize if plotsize < 18, detail
	*** mean 0.58, max 16.67, min 0.004, std. dev. 0.932
	
	list 			plotsize selfreport if plotsize > 18 & !missing(plotsize)
	*** gps plotsize is almost a hundred times larger self reported, which means a decimal point misplacement.
	
* recode outlier to be 1/100
	replace 		plotsize = plotsize/100 if plotsize > 18
		
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.88 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good, largest size is 16 ha
	
* summarize before imputation
	sum				plotsize
	*** mean 0.58, max 16.67, min 0.004

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			admin_1 admin_2 admin_3 admin_4 hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.admin_2 selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			plotsize_1_
	*** mean 0.62, max 16.99, min 0.004
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** strong correlation 0.87
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

	
***********************************************************************
**## 6 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid hh hhid_pnl rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector year wgt13 wgt_pnl prcid ea ///
						plotsize irr_any ownshp_rght_a ownshp_rght_b ///
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
	
	order			hhid hh hhid_pnl rotate admin_1 admin_2 admin_3 ///
						admin_4 ea sector year wgt13 wgt_pnl prcid ///
						tenure plotsize
	
	compress

* save file
	save 			"$export/2013_agsec2a.dta", replace

* close the log
	log	close

/* END */
