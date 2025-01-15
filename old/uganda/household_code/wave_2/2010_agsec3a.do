* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 25 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 post-planting inputs (2010_AGSEC3A) for the 1st season
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
	* complete

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2010_agsec3a_plt", append

	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 2 season A
	use 			"$root/2010_AGSEC3A.dta", clear
		
	rename 			HHID hhid
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

	

************************************************************************
**# 2 - fertilizer, pesticide and herbicide
************************************************************************

* fertilizer use
	rename 		a3aq14 fert_any
	rename 		a3aq16 fert_qty
	rename		a3aq4 fert_org

* replace the missing fert_any with 0
	tab 			fert_qty if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 269 changes
			
	sum 			fert_qty if fert_any == 1, detail
	*** mean 39.3, min 0.2, max 300

* replace zero to missing, missing to zero, and outliers to missing
	replace			fert_qty = . if fert_qty > 264
	*** 3 outliers changed to missing
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	
************************************************************************
**# 3 - pesticide & herbicide
************************************************************************

* pesticide & herbicide
	tab 			a3aq26
	*** 4.18 percent of the sample used pesticide or herbicide
	
	gen 			pest_any = 1 if a3aq27 != . & a3aq27 != 4
	replace			pest_any = 0 if pest_any == .
	
	gen 			herb_any = 1 if a3aq27 == 4 | a3aq27 == 96
	replace			herb_any = 0 if herb_any == .
	
	
************************************************************************
**# 4 - labor 
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
	gen				fam = 1 if a3aq38 > 0
	replace			fam = 0 if fam == .
	
* how many household members worked on this plot?
	tab 			a3aq38
	*** family labor is from 0 - 10 people
	
	replace			a3aq39 = . if a3aq39 > 365
	*** 2 changes made

* fam lab = number of family members who worked on the farm*days they worked
	gen 			fam_lab = a3aq38*a3aq39
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 2300, min 0, mean 114.8
	
* hired labor 
* hired men days
	rename	 		a3aq42a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3aq42b hired_women 
		
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
	gen 			hrd_lab = hired_men + hired_women	
	
* generate labor days as the total amount of labor used on plot in person days
	gen				tot_lab = fam_lab + hrd_lab
	
	sum 			tot_lab
	*** mean 118.9, max 2300, min 0
	
	
************************************************************************
**# 6 - end matter, clean up to save
************************************************************************

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
	save 			"$export/2010_agsec3a.dta", replace

* close the log
	log	close

/* END */
