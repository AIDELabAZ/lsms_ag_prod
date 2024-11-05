* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 post-planting inputs (2019_AGSEC3A) for the 1st season
	* questionaire 3B is for 2nd season
	* cleans
		* fertilizer (inorganic and organic)
		* pesticide and herbicide
		* labor
		* plot management
	* merge in manager characteristics from gsec2 gsec4
	* output cleaned measured input file
	* 3B - 5B are questionaires for the first planting season of 2019 (main)
	* 3A - 5A are questionaires for the second planting season of 2018 (secondary)

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* complete
	

***********************************************************************
**#0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_agsec3b", append
	
***********************************************************************
**#1 - import data and rename variables, manipulate hh labor 
***********************************************************************

* import 3b_1 data for household labor - to be integrated later 

* import wave 8 season B1
	use 			"$root/agric/agsec3b_1.dta", clear
		
* collapse household labor
	collapse	 	(sum) s3bq33_1, by (parcelID pltid hhid)
	rename 			parcelID prcid
	rename 			s3bq33_1 fam_lab 
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
*	*** max 360, mean 35, min 0

	save 			"$export/agsec3b_1hh.dta", replace 	
		
***********************************************************************
**#2 - import data and rename variables
***********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec3b.dta", clear		
	
* Rename ID variables
	rename			parcelID prcid
	recast 			str32 hhid
	
	describe
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

* clean up ownership data to make 2 ownership variables
	gen	long		pid = s3bq03_3
	replace			pid = s3bq03_4a if pid == .
	
	gen	long		pid2 = s3bq03_4b

	
***********************************************************************
**# 2 - merge in manager characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2019_gsec2.dta"
	* 80 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2019_gsec4.dta"
	* 80 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_a
	rename			gender gender_mgmt_a
	rename			age age_mgmt_a
	rename			edu edu_mgmt_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2019_gsec2.dta"
	* 3,024 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2019_gsec4.dta"
	* 3,024 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_b
	rename			gender gender_mgmt_b
	rename			age age_mgmt_b
	rename			edu edu_mgmt_b

	gen 			two_mgmt = 1 if manage_rght_a != . & manage_rght_b != .
	replace 		two_mgmt = 0 if two_mgmt ==.	

***********************************************************************
**#4 - fertilizer
***********************************************************************

* fertilizer use
	rename 		s3bq13 fert_any
	rename 		s3bq15 fert_qty
	rename 		s3bq04 fert_org
		
* replace the missing fert_any with 0
	tab 			fert_qty if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 1 real changes
			
	summarize 			fert_qty if fert_any == 1
	*** mean 42, min 1, max 900

* replace zero to missing, missing to zero, and outliers to mizzing
	replace			fert_qty = . if fert_qty > 187
	*** 7 outliers changed to missing
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	*** 6,226 real changes made
	
***********************************************************************
**#5 - pesticide & herbicide
***********************************************************************

* pesticide & herbicide
	tab 		s3bq22
	*** 6 percent of the sample used pesticide or herbicide
	tab 		s3bq23
	
	gen 		pest_any = 1 if s3bq23 != . & s3bq23 != 4 & s3bq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if s3bq23 == 4 | s3bq23 == 96
	replace		herb_any = 0 if herb_any == .
	*** 6,245 real changes made
	
***********************************************************************
**# 6 - labor 
***********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* includes all labor tasks performed on a plot during the first crop season
	

***********************************************************************
**## 6.a - hired labor 
***********************************************************************

* hired labor 
* hired men days
	rename	 		s3bq35a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			s3bq35b hired_women 
		
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
	
* generate hired labor days
	gen				hrd_lab = hired_men + hired_women
	
	
***********************************************************************
**## 6.b - family labor 
***********************************************************************

* This wave asked about specific household members who worked on the plot rather than the total number of members 

* merge in family labor 
	merge 1:1 		hhid prcid pltid using "$export/agsec3b_1hh"
	*** matched 6,378, not matched 67 from using, none from master
	*** this means that 67 plots only used hired labor, seems fine

* check values of family labor
	sum				fam_lab, detail
*	*** max 360, mean 34, min 0
	
* generate labor days as the total amount of labor used on plot in person days
	gen				tot_lab = fam_lab + hrd_lab
	
	sum 			tot_lab
	*** mean 37, max 360, min 0	
	
	
***********************************************************************
**#7 - end matter, clean up to save
***********************************************************************

	keep 			hhid prcid pest_any herb_any tot_lab ///
					fam_lab hrd_lab fert_qty pltid fert_org  ///
					manage_rght_a manage_rght_b gender_mgmt_a age_mgmt_a ///
					edu_mgmt_a gender_mgmt_b age_mgmt_b edu_mgmt_b two_mgmt
		
	lab var			manage_rght_a "pid for first manager"
	lab var			manage_rght_b "pid for second manager"	
	lab var			gender_mgmt_a "Gender of first manager"
	lab var			age_mgmt_a "Age of first manager"
	lab var			edu_mgmt_a "=1 if first manager has formal edu"
	lab var			gender_mgmt_b "Gender of second manager"	
	lab var			age_mgmt_b "Age of second manager"
	lab var			edu_mgmt_b "=1 if second manager has formal edu"
	lab var			two_mgmt "=1 if there is joint management"
	lab var			prcid "Parcel ID"
	lab var			fert_org "=1 if organic fertilizer used"
	lab var			fert_qty "Inorganic Fertilizer (kg)"
	lab var			pltid "Plot ID"
	lab var			pest_any "=1 if pesticide used"
	lab var			herb_any "=1 if herbicide used"
	lab var			tot_lab "Total labor (days)"
	lab var			fam_lab "Total family labor (days)"
	lab var			hrd_lab "Total hired labor (days)"

	isid			hhid prcid pltid
	
	compress
	

**# save file
	save 			"$export/2019_agsec3b.dta", replace

* close the log
	log	close

/* END */	
