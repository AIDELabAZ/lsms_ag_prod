* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 25 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 post-planting inputs (2011_AGSEC3A) for the 1st season
	* questionaire 3B is for 2nd season
	* cleans
		* fertilizer (inorganic and organic)
		* pesticide and herbicide
		* labor
		* plot management
	* merge in manager characteristics from gsec2 gsec4
	* output cleaned measured input file

* assumes
	* access to the raw data
	* access to cleaned GSEC2 and GSEC4
	* mdesc.ado

* TO DO:
	* complete
	

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2011_agsec3a_plt", append
	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 3 season A
	use 			"$root/2011_AGSEC3A.dta", clear
	
* unlike other waves, HHID is a numeric here
	rename 			HHID hhid
	format 			%16.0g hhid
	
	rename			parcelID prcid
	rename			plotID pltid

	replace			prcid = 1 if prcid == .
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid
	
	format 			%16.0g a3aq3_3
	format			%16.0g a3aq3_4a
	format 			%16.0g a3aq3_4b

* clean up ownership data to make 2 ownership variables (management)
	gen long				pid = a3aq3_3 
	replace			pid = a3aq3_4a if pid == .
	
	gen				pid2 = a3aq3_4b
	
	format			%16.0g pid
	format 			%16.0g pid2
	
***********************************************************************
**# 2 - merge in manager characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 41 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 43 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_a
	rename			gender gender_mgmt_a
	rename			age age_mgmt_a
	rename			edu edu_mgmt_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 3,080 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 3,083 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_b
	rename			gender gender_mgmt_b
	rename			age age_mgmt_b
	rename			edu edu_mgmt_b

	gen 			two_mgmt = 1 if manage_rght_a != . & manage_rght_b != .
	replace 		two_mgmt = 0 if two_mgmt ==.		

************************************************************************
**# 3 - merge location data
************************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2011_GSEC1_plt"
	*** 1054 unmatched from master
	
	drop if			_merge != 3
	

************************************************************************
**# 4 - fertilizer, pesticide and herbicide
************************************************************************

* fertilizer use
	rename 		a3aq13 fert_any
	rename 		a3aq15 kilo_fert
	
* make a variable that shows  organic fertilizer use
	gen				forg_any =1 if a3aq4 == 1
	replace			forg_any = 0 if forg_any ==.
	*** only 5.18 percent used organic fert

		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 5 changes
			
	sum 			kilo_fert if fert_any == 1, detail
	*** 34.41, min 0.25, max 800

* replace zero to missing, missing to zero, and outliers to mizzing
	replace			kilo_fert = . if kilo_fert > 264
	*** 3 outliers changed to missing

* encode district to be used in imputation
	encode 			district, gen (districtdstrng) 	
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	*** the finer geographical variables will proxy for soil quality which is a determinant of fertilizer use
	mi register			imputed kilo_fert // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm kilo_fert  i.districtdstrng fert_any, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset		
	
* how did impute go?	
	sum 		kilo_fert_1_ if fert_any == 1, detail
	*** max 200, mean 23.83, min 0.25
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 3 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2

* variable showing if hh purchased fertilizer

	gen 			fert_purch_any = 1 if a3aq16 ==1
	replace 		fert_purch_any = 0 if fert_purch_any ==. 
	*** 1.68 % purchased fert
		
* calculate price of fertilizer
	rename 			a3aq17 kfert_purch
	rename			a3aq18 vle_fert_purch
	
	gen				fert_price = vle_fert_purch/kfert_purch
	label var 		fert_price "price per kilo (shillings)"
	
	count if 		fert_price== . &  fert_purch_any == 1
	* 0 observations missing price for hh who purchased fertilizer
	
	
************************************************************************
**# 5 - pesticide & herbicide
************************************************************************

* pesticide & herbicide
	tab 		a3aq22
	*** 5.08 percent of the sample used pesticide or herbicide
	tab 		a3aq23
	
	gen 		pest_any = 1 if a3aq23 != . & a3aq23 != 4 & a3aq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if a3aq23 == 4 | a3aq23 == 96
	replace		herb_any = 0 if herb_any == .

	
************************************************************************
**# 6 - labor 
************************************************************************
	* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
	* 7 days * 13 weeks = 91 days for land prep and planting
	* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
	* 7 days * 13 weeks = 91 days for harvesting
	* we will also exclude child labor_days
	* in this survey we can't tell gender or age of household members
	* since we can't match household members we deal with each activity seperately
	* includes all labor tasks performed on a plot during the first cropp season

* family labor	
* make a binary if they had family work
	gen				fam = 1 if a3aq31 > 0
	
* how many household members worked on this plot?
	tab 			a3aq31
	replace			a3aq31 = 12 if a3aq31 == 25000
	*** family labor is from 0 - 12 people
	
	sum 			a3aq32, detail
	*** mean 32.8, min 1, max 300
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = a3aq31*a3aq32
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 3000, mean 9780, min 0
	
* hired labor 
* hired men days
	rename	 		a3aq35a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3aq35b hired_women 
		
* make a binary if they had hired_men
	gen 			women = 1 if hired_women != . & hired_women != 0
	
* impute hired labor all at once
	sum				hired_men, detail
	sum 			hired_women, detail
	
* replace values greater than 365 and turn missing to zeros
	replace			hired_men = 0 if hired_men == .
	replace			hired_women = 0 if hired_women == .
	
	replace			hired_men = 365 if hired_men > 365
	replace			hired_women = 365 if hired_women > 365
	*** no changes made
	
* generate labor days as the total amount of labor used on plot in person days
	gen				labor_days = fam_lab + hired_men + hired_women
	
	sum 			labor_days
	*** mean 101.45, max 3080, min 0	

* change format of hhid for merging purposes (merging file)

	drop 			hhid 
	rename 			HHID hhid
	
************************************************************************
**# 6 - end matter, clean up to save
************************************************************************

	keep hhid prcid region district subcounty pltid fert_any kilo_fert labor_days region ///
		district county subcounty parish pest_any herb_any parish wgt11  ///
		forg_any fert_price

	compress
	describe
	summarize

* save file
	save 			"$export/2011_AGSEC3A_plt.dta", replace
	
* close the log
	log	close

/* END */	
