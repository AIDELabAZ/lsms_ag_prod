* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 29 Oct 24
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
	* done
	

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
	gen long 		pid =.
	replace 		pid = a3aq3_3 
	replace 		pid = a3aq3_4a if pid == .
	format			%16.0g pid
	
	rename 			a3aq3_4b pid2
	order 			pid2, after(pid)
	

	
***********************************************************************
**# 2 - merge in manager characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	* 207 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2011_gsec4.dta"
	* 282 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_a
	rename			gender gender_mgmt_a
	rename			age age_mgmt_a
	rename			edu edu_mgmt_a
	rename 			member_number member_number_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid


* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2011_gsec2.dta"
	*** 3,407 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2011_gsec4.dta"
	* 3,531 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_b
	rename			gender gender_mgmt_b
	rename			age age_mgmt_b
	rename			edu edu_mgmt_b

	gen 			two_mgmt = 1 if manage_rght_a != . & manage_rght_b != .
	replace 		two_mgmt = 0 if two_mgmt ==.		
	
	
************************************************************************
**# 3 - fertilizer
************************************************************************

* fertilizer use
	rename 		a3aq13 fert_any
	rename 		a3aq15 fert_qty
	rename		a3aq4 fert_org

* replace the missing fert_any with 0
	tab 			fert_qty if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 5 changes
			
	sum 			fert_qty if fert_any == 1, detail
	*** mean 33.6, min 0.2, max 8000

* replace zero to missing, missing to zero, and outliers to missing
	replace			fert_qty = . if fert_qty > 264
	*** 3 outliers changed to missing
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	
	
************************************************************************
**# 5 - pesticide & herbicide
************************************************************************

* pesticide & herbicide
	tab 		a3aq22
	*** 4.978 percent of the sample used pesticide or herbicide
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
	*** mean 32.9, min 1, max 300
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = a3aq31*a3aq32
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 3000, mean 98.40, min 0
	
* hired labor 
* hired men days
	rename	 		a3aq35a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3aq35b hired_women 
		
* make a binary if they had hired_women
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
	
* generate labor days as the total amount of labor used on plot in person days
	gen				tot_lab = fam_lab + hrd_lab
	
	sum 			tot_lab
	*** mean 102, max 3,080, min 0
	
************************************************************************
**# 6 - end matter, clean up to save
************************************************************************

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


* save file
	save 			"$export/2011_agsec3a.dta", replace
	
* close the log
	log	close

/* END */	
