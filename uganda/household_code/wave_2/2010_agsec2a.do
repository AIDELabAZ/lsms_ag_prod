* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 24 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 owned plot info (2009_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2010_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* cleans
		* plot sizes
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
**# 4 - clean parcel size
************************************************************************

* summarize parcel size
	sum 			plotsizeGPS
	***	mean 3.72, max 676, min .01
	*** no plotsizes that are zero
	
	sum				plotsizeSR
	*** mean 2.18, max 100, min .01

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 1,073 missing, 34% of observations
	
* convert acres to square meters
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* check correlation between the two
	corr 			plotsize selfreport
	*** 0.25 correlation, reasonably good between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** values over 100 are clearly wrong
	*** the ones in the 70s I am unsure about
	*** the ones in the 30s and 40s look okay

	replace			plotsize = . if plotsize > 40
	*** 9 change made

* gps on the larger side vs self-report
	tab				plotsize if plotsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 3 & !missing(plotsize)
	*** this is really low, 0.154, compared to 2009 which was 0.616

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** this is basically the same, 0.174
		
* correlation for extremely small plots	
	corr			plotsize selfreport if plotsize < .01 & !missing(plotsize)
	*** this is higher, but negative, -0.403, which is strange in itself
	
* summarize before imputation
	sum				plotsize
	*** mean 0.956, max 35.29, min 0.004
	
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
	*** mean 1.01, max 35.29, min 0.004
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** 0.612 better correlation
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
* impute final observations that don't not have self reported
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			region district hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.districtdstrng, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	mdesc 			plotsize
	*** none missing
	
	
************************************************************************
**# 4 - end matter, clean up to save
************************************************************************

	keep 			hhid prcid region district county subcounty ///
					parish hh_status2010 spitoff09_10 spitoff10_11 wgt10 ///
					plotsize irr_any

	compress
	describe
	summarize

* save file
	save 			"$export/2010_AGSEC2A_plt.dta", replace


* close the log
	log	close

/* END */
