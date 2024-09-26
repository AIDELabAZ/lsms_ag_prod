* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 25 Sep 2024
* Edited by: rg
* Stata v.18, mac

* does
	* seed use
	* reads Uganda wave 5 crops grown and types of seeds info (AGSEC4B) for the 1st season
	* 3A - 5A are questionaires for the second planting season
	* 3B - 5B are questionaires for the first planting season

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* seed quantity and seed price 
	* conversion file for units
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_5/raw"  
	global export 	"$data/household_data/uganda/wave_5/refined"
	global logout 	"$data/household_data/uganda/logs"
	global conv 	"$data/household_data/uganda/conversion_files"  
	
* open log	
	cap log 		close
	log using 		"$logout/2015_agsec4a_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 5 season A
	use 			"$root/agric/AGSEC4B.dta", clear
	
* rename variables	
	rename 			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename 			ACrop2_ID cropid2
	rename 			cropID_other cropid3
	rename			a4bq11b unit
	rename			abaq11a seed_qty
	
	sort 			hhid prcid pltid cropid cropid2 
	
	mdesc 			hhid prcid pltid cropid cropid2
	* we have 5 obs missing pltid and 1 cropid
	drop if			pltid ==. | cropid ==.
	* 6 observations dropped

	isid 			hhid prcid pltid cropid	cropid2


	
***********************************************************************
**# 2 - merge kg conversion file and create seed quantity
***********************************************************************

	describe		unit
	label list		a4bq11b 
	tab				unit
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 198 from master 
	*** unmatched 717 from using
	*** total unmatched, 915
	
	
* drop from using
	drop 			if _merge == 2
	** 717 obs dropped

* how many unmatched had a harvest of 0
	tab 			a5bq6a if _merge == 1
	*** 0% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** this isn't it either
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab				unit if _merge == 1, nolabel
	

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5bq6a == 0 & _merge == 1
	*** 0 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 4 changes
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 1 change
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 1 change
		
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 2 changes
		
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 8 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 1 change
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 1 change
		
	* jerrican 2 kgs
		replace 		ucaconversion = 2 if unit == 18 & _merge == 1
		*** 1 change 
		

	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 1 change 

	* 15 kg plastic Basin
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 1 change
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 3 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 0.5 if unit == 30 & _merge == 1	
		*** 1 change
		
	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 2 changes 
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 3 changes

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 1 change

		
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 167 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 579 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	
	tab				cropid
	*** beans are the most numerous crop being 23.32% of crops planted
	***	maize is the second highest being 22.9%
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	
* replace missing harvest quantity to 0
	replace 		a5bq6a = 0 if a5bq6a == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = a5bq6a*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted
	
* summarize harvest quantity
	sum				harvqtykg
	*** no values > 100,000
	
	mdesc 			harvqtykg
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 271.79 mean, 13,800 max
	

***********************************************************************
**# 3 - type of crop stand
***********************************************************************

* make a variable that shows if intercropped or not
	gen				intrcrp_any =1 if a4bq8 == 2
	replace			intrcrp_any = 0 if intrcrp_any ==.

* variable for use of seeds
	gen				seeds_any = 1 if a4bq16 ==1
	replace			seeds_any = 0 if a4bq16 ==.
	
	rename 			abaq11a 
		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 1 change
			
	sum 			kilo_fert if fert_any == 1, detail
	*** mean 33.19, min 0.25, max 1000

* replace zero to missing, missing to zero, and outliers to missing
	replace			kilo_fert = . if kilo_fert > 264
	*** 1 outlier changed to missing

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
	sum 			kilo_fert_1_ if fert_any == 1, detail
	*** max 100, mean 23.5, min 0.25
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 1 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	

* calculate price of fertilizer
	rename 			a3bq17 kfert_purch
	rename			a3bq18 vle_fert_purch
	
	gen				price_fert = vle_fert_purch/kfert_purch
	label var 		price_fert "price per kilo (shillings)"
	
	
********doing the same for organic fertilizer (forg)*******
	
* replace the missing fert_any with 0
	tab 			kilo_forg if forg_any == .
	*** no observations
	
	replace			forg_any = 2 if forg_any == . 
	*** 0 changes
			
	sum 			kilo_forg if forg_any == 1, detail
	*** mean 268.6, min 12, max 1500

* replace zero to missing, missing to zero, and outliers to missing
	replace			kilo_forg = . if kilo_forg > 1000
	*** 1 outlier changed to missing

	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	*** the finer geographical variables will proxy for soil quality which is a determinant of fertilizer use
	mi register			imputed kilo_forg // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm kilo_forg  i.districtdstrng forg_any, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset		
	
* how did impute go?	
	sum 		kilo_forg_1_ if forg_any == 1, detail
	*** max 1000, mean 262, min 12
	
	replace			kilo_forg = kilo_forg_1_ if forg_any == 1
	*** 1 changed
	
	drop 			kilo_forg_1_ mi_miss
	
* record fert_any
	replace			forg_any = 0 if forg_any == 2

	
	
***********************************************************************
**# 4 - pesticide & herbicide
***********************************************************************

* pesticide & herbicide
	tab 		a3bq22
	*** 3.83 percent of the sample used pesticide or herbicide
	tab 		a3bq23
	
	gen 		pest_any = 1 if a3bq23 != . & a3bq23 != 4 & a3bq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if a3bq23 == 4 | a3bq23 == 96
	replace		herb_any = 0 if herb_any == .

	
***********************************************************************
**# 5 - labor 
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
* make a binary if they had family work
	gen				fam = 1 if a3bq33 > 0
	
* how many household members worked on this plot?
	tab 			a3bq33
	*** family labor is from 0 - 13 people
	
* hours worked on plot are recorded per household member not total
* create variable of total days worked on plot
	egen			days_worked = rowtotal (a3bq33a_1 a3bq33b_1 ///
					a3bq33c_1 a3bq33d_1 a3bq33e_1)
	
	sum 			days_worked, detail
	*** mean 42.7, min 0, max 400
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = a3bq33*days_worked
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 2,400, mean 140.4, min 0
	
* hired labor 
* hired men days
	rename	 		a3bq35a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3bq35b hired_women 
		
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
	*** mean 142.9, max 2,400, min 0	

	
***********************************************************************
**# 6 - end matter, clean up to save
***********************************************************************

	keep 			hhid hh_agric prcid region district subcounty ///
					parish  wgt15 hwgt_W4_W5 ///
					ea rotate fert_any kilo_fert labor_days pest_any herb_any pltid ///
					kilo_forg forg_any intrcrp_any

	compress
	describe
	summarize

* save file
	save 			"$export/2015_agsec4a_plt.dta", replace

* close the log
	log	close

/* END */	
