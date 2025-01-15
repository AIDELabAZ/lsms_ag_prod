* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 6 Nov 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 8 crops grown and seed (2019_AGSEC4A) for the 1st season
	* questionaire 4B is for 2nd season
	* cleans
		* planting date
		* seeds
		* crops
	* output cleaned seed and planting date file
	* 3B - 5B are questionaires for the first planting season of 2019 (main)
	* 3A - 5A are questionaires for the second planting season of 2018 (secondary)

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_agsec4a_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/agric/agsec4b.dta", clear
	
* order and rename variables
	order			hhid

	rename			parcelID prcid
	rename 			cropID cropid
	rename			s4bq11b unit
	rename			s4bq11a seed
	rename 			s4bq13 seed_type
	rename 			s4bq07 area_plnt
	rename			s4bq09 prct_plnt
	rename			s4bq09_1 plnt_month
	rename			s4bq09_2 plnt_year
	
	mdesc 			hhid prcid pltid cropid 
	* we have 1 obs missing pltid and cropid
	

	isid 			hhid prcid pltid cropid	
	
* make a variable that shows if intercropped or not
	gen				intrcrp = 1 if s4bq08 == 2
	replace			intrcrp = 0 if intrcrp ==.

* drop cropid is annual, other, fallow, pasture, and trees
	drop 			if cropid > 699
	*** 2,351 observations deleted 
	
	drop 			if cropid ==530
	*** 31 obs dropped
	
	
***********************************************************************
**# 2 - percentage planted 	
***********************************************************************

* convert area to hectares 
	replace 		area_plnt = area_plnt * 0.404686
		
* create variable for percentage of plot area
	replace 		prct_plnt = prct_plnt / 100
	
* there are obs that reported pure stand but don't have a prct_plnt
	replace 		prct_plnt =1 if s4bq08 ==1
	*** 3,461 changes
	
	gen 			crop_area = area_plnt * prct_plnt
	label var 		crop_area "Area planted (ha)"
	
	mdesc 			crop_area
	*** 36 missing which don't have area planted
	
	drop 			if area_plnt ==.
	

***********************************************************************
**# 3 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type, missing
	* 5,855 used traditional
	* 391 used improved
	* 692 missing

* create a variable showing used of seed 
	gen 			seed_any = 1 if s4bq16 == 1
	replace			seed_any = 0 if seed_any == .
	tab				seed_any
	* 90 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			s4bq11b
	
	gen 				seed_qty = . 
	label var			seed_qty "Seed used (kg)"
	
	*kgs
		replace 		seed_qty = seed if unit == 1
		*** 3,441  changes
		count if 		unit == 1 & seed ==1 
		*** 297 observations  
		
	* grams 
		replace 		seed_qty = seed/1000 if unit == 2 
		*** 47 changes 
		*** check values, observations with 1,2,8, 0.25 grams
		
	* sack 120 kgs
		replace			seed_qty = seed * 120 if unit == 9
		*** 152 changes  
		
	* sack 100 kgs 
		replace 		seed_qty = seed * 100 if unit == 10
		*** 707 changes 
		
	* sack 80 kgs 
		replace 		seed_qty = seed * 80 if unit == 11
		***  47 changes 	

	* sack 50 kgs 
		replace 		seed_qty = seed * 50 if unit == 12
		***  98 changes 
		
	* Tin 20 lts
		replace 		seed_qty = seed * 20 if unit == 20
		***  66 changes 	

	* Tins 5 lts 
		replace 		seed_qty = seed * 5 if unit == 21
		***  36 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty = seed * 15 if unit == 22
		***  339 changes
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty = seed * 2 if unit == 29
		***  186 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty = seed * 1 if unit == 30
		***  43 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty = seed * 0.5 if unit == 31
		***  243 changes 
		
	* basket 20 kg
		replace 		seed_qty = seed * 20 if unit == 37
		***  9 changes 

	* basket 10 kg
		replace 		seed_qty = seed * 10 if unit == 38
		***  2 changes 
		
	* basket 5 kg
		replace 		seed_qty = seed * 5 if unit == 39
		***  7 changes 

	
* summarize seed quantity
	sum				seed_qty
	*** min 0 
	*** max 242,280
	*** there are two hh who reported using seeds and then reported 0 as qty
	
	mdesc 			seed_qty
	* 1,541 missing
	
	tab				seed_qty if seed_any == 0
	* no qty if didn't use seed
		
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************

	keep 			hhid prcid cropid pltid intrcrp seed_qty ///
						seed_type crop_area plnt_month plnt_year ///
						area_plnt prct_plnt 

	lab var			seed_type "Traditional/improved"
	lab var			intrcrp "=1 if intercropped"
	lab var			area_plnt "Total area of plot planted"
	lab var			prct_plnt "Percent planted to crop"
					
	isid			hhid prcid pltid cropid	
		
	order			hhid prcid pltid cropid plnt_month plnt_year intrcrp
	
	compress


* save file
	save 			"$export/2019_agsec4a.dta", replace

* close the log
	log	close

/* END */	
