* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 post-planting inputs (2013_AGSEC3A) for the 1st season
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
	log using 			"$logout/2013_agsec3a_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/agric/AGSEC3A.dta", clear
	
* rename variables 
	rename			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid

	replace			prcid = 1 if prcid == .
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

* clean up ownership data to make 2 ownership variables
	gen	long		PID = a3aq3_3
	replace			PID = a3aq3_4a if PID == .
	
	gen	long		PID2 = a3aq3_4b

	
***********************************************************************
**# 2 - merge in manager characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid PID using "$export/2013_gsec2.dta"
	* 41 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid PID using "$export/2013_gsec4.dta"
	* 43 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			PID manage_rght_a
	rename			gender gender_mgmt_a
	rename			age age_mgmt_a
	rename			edu edu_mgmt_a
	
* rename PID for b to just PID so we can merge	
	rename			PID2 PID

* merge in age and gender for owner b
	merge m:1 		hhid PID using "$export/2013_gsec2.dta"
	* 3,080 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid PID using "$export/2013_gsec4.dta"
	* 3,083 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			PID manage_rght_b
	rename			gender gender_mgmt_b
	rename			age age_mgmt_b
	rename			edu edu_mgmt_b

	gen 			two_mgmt = 1 if manage_rght_a != . & manage_rght_b != .
	replace 		two_mgmt = 0 if two_mgmt ==.	
	
	
***********************************************************************
**# 3 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2013_agsec1"
	*** 101 unmatched from using
	*** 7,550 matched
	
	drop if			_merge != 3
	

***********************************************************************
**# 4 - fertilizer
***********************************************************************

* fertilizer use
	rename 		a3aq13 fert_any
	rename 		a3aq15 kilo_fert
	rename		a3aq4 fert_org

* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 7 changes
			
	sum 			kilo_fert if fert_any == 1, detail
	*** mean 28.53, min 0.2, max 1,000

* replace zero to missing, missing to zero, and outliers to missing
	replace			kilo_fert = . if kilo_fert > 264
	*** 2 outliers changed to missing

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
	*** max 150, mean 20.71, min 0.2
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 2 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	
* variable showing if hh purchased fertilizer
	gen 			fert_purch_any = 1 if a3aq16 ==1
	replace 		fert_purch_any = 0 if fert_purch_any ==. 
	*** 1.9 % purchased fert
		
* calculate price of fertilizer
	rename 			a3aq17 fert_purch
	rename			a3aq18 fert_vle

	gen 			fert_price = fert_vle / fert_purch
	label var 		fert_price "Price of inorganic fert per kg in Shilling"
		
	count if 		fert_vle == . &  fert_purch_any == 1
	* 0 observations missing value for hh who purchased fertilizer

	
***********************************************************************
**# 5 - pesticide & herbicide
***********************************************************************

* pesticide & herbicide
	tab 		a3aq22
	*** 4.83 percent of the sample used pesticide or herbicide
	
	tab 		a3aq23
	
	gen 		pest_any = 1 if a3aq23 != . & a3aq23 != 4 & a3aq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if a3aq23 == 4 | a3aq23 == 96
	replace		herb_any = 0 if herb_any == .

	
***********************************************************************
**# 6 - labor 
***********************************************************************
	* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
	* 7 days * 13 weeks = 91 days for land prep and planting
	* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
	* 7 days * 13 weeks = 91 days for harvesting
	* we will also exclude child labor_days
	* in this survey we can't tell gender or age of household members
	* since we can't match household members we deal with each activity seperately
	* includes all labor tasks performed on a plot during the first cropp season

* family labor	
* in this wave, it is asked about the specific household members who worked on the plot rather than the total number of members who did

* create a new variable counting how many household members worked on the plot
	egen 			household_count = rownonmiss(a3aq33a a3aq33b ///
					a3aq33c a3aq33d a3aq33e)
	
* make a binary if they had family work
	gen				fam = 1 if household_count > 0
	
* how many household members worked on this plot?
	tab 			household_count
	*** family labor is from 0 - 5 people
	
* hours worked on plot are recorded per household member not total
* create variable of total days worked on plot
	egen			days_worked = rowtotal (a3aq33a_1 a3aq33b_1 ///
					a3aq33c_1 a3aq33d_1 a3aq33e_1)
	
	sum 			days_worked, detail
	*** mean 42.01, min 0, max 450
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = household_count*days_worked
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 2250, mean 134.7, min 0
	
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
	
* generate hired labor days
	gen				hrd_lab = hired_men + hired_women
	
* generate labor days as the total amount of labor used on plot in person days
	gen				labor_days = fam_lab + hrd_lab
	
	sum 			labor_days
	*** mean 137.59, max 2,250, min 0	

	
***********************************************************************
**# 7 - end matter, clean up to save
***********************************************************************

	keep 			hhid hhid_pnl prcid region district subcounty ///
					parish wgt13 ea rotate pest_any herb_any labor_days ///
					fam_lab hrd_lab kilo_fert pltid fert_org fert_price ///
					manage_rght_a manage_rght_b gender_mgmt_a age_mgmt_a ///
					edu_mgmt_a gender_mgmt_b age_mgmt_b edu_mgmt_b two_mgmt
		
	lab var			manage_rght_a "PID for first manager"
	lab var			manage_rght_b "PID for second manager"	
	lab var			gender_mgmt_a "Gender of first manager"
	lab var			age_mgmt_a "Age of first manager"
	lab var			edu_mgmt_a "=1 if first manager has formal edu"
	lab var			gender_mgmt_b "Gender of second manager"	
	lab var			age_mgmt_b "Age of second manager"
	lab var			edu_mgmt_b "=1 if second manager has formal edu"
	lab var			two_mgmt "=1 if there is joint management"
	lab var			prcid "Parcel ID"
	lab var			district "District"
	lab var			subcounty "Subcounty"
	lab var			parish "Parish"
	lab var			fert_org "=1 if organic fertilizer used"
	lab var			kilo_fert "Inorganic Fertilizer (kg)"
	lab var			pltid "Plot ID"
	lab var			pest_any "=1 if pesticide used"
	lab var			herb_any "=1 if herbicide used"
	lab var			labor_days "Total labor (days)"
	lab var			fam_lab "Total family labor (days)"
	lab var			hrd_lab "Total hired labor (days)"

	isid			hhid prcid pltid
	
	order			region district subcounty parish ea hhid hhid_pnl ///
						wgt13 rotate prcid pltid fert_org kilo_fert fert_price ///
						pest_any herb_any
	
	compress
	
* save file
	save 			"$export/2013_agsec3a.dta", replace

* close the log
	log	close

/* END */	
