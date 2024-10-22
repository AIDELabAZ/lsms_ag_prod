* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
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
		
* rename key variables
	rename			HHID hhid
	rename			parcelID prcid
	rename 			a2bq4 plotsizeGPS
	rename 			a2bq5 plotsizeSR
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq16 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "=1 if irrigated"
	*** there are 8 irrigated	

* clean up ownership data to make 2 ownership variables
	gen	long		PID = a2bq21a	
	gen	long		PID2 = a2bq21b

* generate tenure variable based on fact that this is all rented plots
	gen				tenure = 0
	lab var			tenure "=1 if owned"
	
***********************************************************************
**# 2 - merge in ownership characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid PID using "$export/2013_gsec2.dta"
	* 11 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid PID using "$export/2013_gsec4.dta"
	* 12 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			PID ownshp_rght_a
	rename			gender gender_own_a
	rename			age age_own_a
	rename			edu edu_own_a
	
* rename PID for b to just PID so we can merge	
	rename			PID2 PID

* merge in age and gender for owner b
	merge m:1 		hhid PID using "$export/2013_gsec2.dta"
	* 421 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid PID using "$export/2013_gsec4.dta"
	* 422 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			PID ownshp_rght_b
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
	
	keep			if a2bq12a == 1
	*** 344 observations deleted	

	
***********************************************************************
**# 5 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.06, max 16.8, min .07
	
	sum				plotsizeSR
	*** mean .97, max 25, min .1

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 822 missing, 87% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.43, min 0.02, max 6.79, std. dev. .66
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.39, min 0.04, max 10.11, std. dev. .53
	
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.96 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good

* summarize before imputation
	sum				plotsize
	*** mean 0.43, min 0.02, max 6.79

* encode district to be used in imputation
	encode district, gen (districtdstrng) 	

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			region district hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.districtdstrng selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			plotsize_1_
	*** mean 0.41, max 6.7, min .02
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** high correlatio, 0.91
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

	
***********************************************************************
**# 6 - appends agsec2a
***********************************************************************

	keep 			hhid hhid_pnl prcid region district subcounty ///
						parish ea wgt13 plotsize irr_any rotate ///
						ownshp_rght_a ownshp_rght_b gender_own_a ///
						age_own_a edu_own_a gender_own_b age_own_b ///
						edu_own_b two_own tenure
						
	lab var			ownshp_rght_a "PID for first owner"
	lab var			ownshp_rght_b "PID for second owner"	
	lab var			gender_own_a "Gender of first owner"
	lab var			age_own_a "Age of first owner"
	lab var			edu_own_a "=1 if first owner has formal edu"
	lab var			gender_own_b "Gender of second owner"	
	lab var			age_own_b "Age of second owner"
	lab var			two_own "=1 if second owner has formal edu"
	lab var			prcid "Parcel ID"
	lab var			district "District"
	lab var			subcounty "Subcounty"
	lab var			parish "Parish"

* append owned plots
	append			using "$export/2013_agsec2a.dta"
	
* drop duplicate
	duplicates 		drop hhid prcid, force
	* 0 deleted
					
***********************************************************************
**# 7 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid

	order			region district subcounty parish ea hhid hhid_pnl ///
						wgt13 rotate prcid tenure plotsize
	
	compress

* save file
	save 			"$export/2013_agsec2.dta", replace

* close the log
	log	close

/* END */
