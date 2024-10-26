* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 1 post-planting inputs (2009_AGSEC3A) for the 1st season
	* questionaire 3B is for 2nd season
	* cleans
		* fertilizer (inorganic and organic)
		* pesticide and herbicide
		* labor
		* plot management
	* merge in manager characteristics from gsec2 gsec4
	* output cleaned measured input file
	
* assumes
	* access to all raw data
	* acess to cleaned GSEC2 and GSEC4
	* mdesc.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2009_agsec3a_plt", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 2 season A
	use 			"$root/2009_AGSEC3A.dta", clear
		
	rename 			Hhid hhid
	rename			A3aq1 prcid 
	rename 			A3aq3 pltid
	

	
* drop observations missing prcid or pltid 
	*** observations missing prcid or pltid are missing in all other variables too
	drop 			if prcid == . | pltid == .
	*** 1098 observations deleted

	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

		
***********************************************************************
**# 2 - fertilizer
***********************************************************************

* fertilizer use
	rename 		A3aq14 fert_any
	rename 		A3aq16 fert_qty
	rename		A3aq4 fert_org

* replace the missing fert_any with 0
	tab 			fert_qty if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 269 changes
			
	sum 			fert_qty if fert_any == 1, detail
	*** mean 90.6, min 0.2, max 7,000

* replace zero to missing, missing to zero, and outliers to missing
	replace			fert_qty = . if fert_qty > 264
	*** 1 outlier changed to missing
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2

	
	
***********************************************************************
**# 3 - pesticide & herbicide
***********************************************************************

* pesticide & herbicide
	tab 			A3aq26
	replace  		A3aq26 = 2 if A3aq26 == 5
	*** 4.61 percent of the sample used pesticide or herbicide
	
	tab 			A3aq27
	
	gen 			pest_any = 1 if A3aq27 != . & A3aq27 != 4
	replace			pest_any = 0 if pest_any == .
	
	gen 			herb_any = 1 if A3aq27 == 4 | A3aq27 == 96
	replace			herb_any = 0 if herb_any == .	
	
	
***********************************************************************
**# 4 - labor 
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
	gen				fam = 1 if A3aq38 > 0
	replace			fam = 0 if fam == .
	
* how many household members worked on this plot?
	tab 			A3aq38
	*** family labor is from 0 - 94 people
	
* limit family size to 15 people and replace missing with zero
	replace			A3aq38 = 0 if A3aq38 == .
	replace			A3aq38 = 15 if A3aq38 > 15
	*** 278 missing to zero, 10 large families downsized
	
	sum 			A3aq39
	*** mean 36.6, min 0, max 999
	*** cannot have max above 365, will replace to missing
	
	replace			A3aq39 = . if A3aq39 > 365
	*** 34 missing values generated

* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = A3aq38*A3aq39
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 3000, min 0, mean 103.4
	
* hired labor 
* hired men days
	rename	 		A3aq42a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			A3aq42b hired_women 
		
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
	*** only two high values replaced
	
* generate hired labor days 
	gen 			hrd_lab = hired_men + hired_women	
	
* generate labor days as the total amount of labor used on plot in person days
	gen				tot_lab = fam_lab + hrd_lab
	
	sum 			tot_lab
	*** mean 108.53, max 3000, min 0
	
	
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************



	keep 			hhid prcid pest_any herb_any tot_lab ///
					fam_lab hrd_lab fert_qty pltid fert_org  ///
					
		
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
	save 			"$export/2009_agsec3a.dta", replace

* close the log
	log	close

/* END */
