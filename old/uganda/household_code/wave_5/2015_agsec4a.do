* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 6 Nov 2024
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 5 crops grown and seed (AGSEC4A) for the 1st season
	* questionaire 4B is for 1st season
	* cleans
		* planting date
		* seeds
		* crops
	* output cleaned seed and planting date file

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_5/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_agsec4a_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 5 season A
	use 			"$root/agric/AGSEC4B.dta", clear
	
* rename variables	
	order 			HHID 
	
	rename 			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename 			ACrop2_ID cropid2
	rename 			cropID_other cropid3
	rename			a4bq11b unit
	rename			abaq11a seed
	rename 			a4bq13 seed_type
	rename 			a4bq7 area_plnt
	rename 			a4bq9 prct_plnt
	rename			a4bq9_1 plnt_month
	rename			a4bq9_2 plnt_year
	sort 			hhid prcid pltid cropid cropid2 
	
	mdesc 			hhid prcid pltid cropid cropid2
	* we have 5 obs missing pltid and 1 cropid
	
	drop if			pltid ==. | cropid ==.
	* 6 observations dropped

	isid 			hhid prcid pltid cropid	cropid2

* make a variable that shows if intercropped or not
	gen				intrcrp = 1 if a4bq8 == 2
	replace			intrcrp = 0 if intrcrp ==.

* drop cropid is annual, other, fallow, pasture, and trees
	drop 			if cropid > 699
	*** 2,099 observations deleted 
	
	drop			if cropid == 530
	*** 32 observations dropped 
	
	
***********************************************************************
**# 2 - percentage planted 	
***********************************************************************

* convert area to hectares 
	replace 		area_plnt = area_plnt * 0.404686
	
* create variable for percentage of plot area
	replace 		prct_plnt = prct_plnt / 100
	
	replace 		prct_plnt = 1 if a4bq8 == 1
	
	mdesc 			prct_plnt
	*** 224 missing prct_plnt
	
	mdesc 			a4bq8 
	*** 170 missing type of crop stand 
	
	drop 			if a4bq8 ==. | prct_plnt ==. | area_plnt == .
	*** 226 observations dropped
	
	gen 			crop_area = area_plnt * prct_plnt
	label var 		crop_area "Area planted (ha)"	
	
	
***********************************************************************
**# 3 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type
	* 5,359 used traditional
	* 439 used improved
	* 3,887 missing 

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4bq16 == 1
	replace			seed_any = 0 if seed_any ==.
	tab 			seed_any
	* 61 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			a4bq11b
	
	gen 				seed_qty = . 
	label var			seed_qty "Seed used (kg)"
	
	*kgs
		replace 		seed_qty = seed if unit == 1
		*** 3,995  changes
		count if 		unit == 1 & seed ==1 
		*** 372 observations  
		
	* grams 
		replace 		seed_qty = seed/1000 if unit == 2 
		*** 51 changes 
		*** check values, observations with 1,2,8, 0.25 grams
		
	* sack 120 kgs
		replace			seed_qty = seed * 120 if unit == 9
		*** 12 changes  
		
	* sack 100 kgs 
		replace 		seed_qty = seed * 100 if unit == 10
		*** 272 changes 
		
	* sack 80 kgs 
		replace 		seed_qty = seed * 80 if unit == 11
		***  121 changes 	

	* sack 50 kgs 
		replace 		seed_qty = seed * 50 if unit == 12
		***  52 changes 
		
	* Tin 20 lts
		replace 		seed_qty = seed * 20 if unit == 20
		***  101 changes 	

	* Tins 5 lts 
		replace 		seed_qty = seed * 5 if unit == 21
		***  6 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty = seed * 15 if unit == 22
		***  314 changes
		count if 		seed == . & unit == 22
		*** 1 missing 
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty = seed * 2 if unit == 29
		***  52 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty = seed * 1 if unit == 30
		***  23 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty = seed * 0.5 if unit == 31
		***  123 changes 
		
	* basket 20 kg
		replace 		seed_qty = seed * 20 if unit == 37
		***  2 changes 

	* basket 10 kg
		replace 		seed_qty = seed * 10 if unit == 38
		***  4 changes 
		
	* basket 5 kg
		replace 		seed_qty = seed * 5 if unit == 39
		***  20 changes 

	* basket 2 kg
		replace 		seed_qty = seed * 2 if unit == 40
		***  3 changes 
			
	
	
* summarize seed quantity
	sum				seed_qty
	*** min 0.00025 
	*** max 9000 
	
	mdesc 			seed_qty if seed_any ==0
	*** 1,712 missing 
		
	
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************
	rename 			hh_agric hhid_pnl
	keep 			hhid hhid_pnl prcid cropid cropid2 pltid intrcrp seed_qty ///
						seed_type crop_area plnt_month plnt_year ///
						area_plnt prct_plnt 

	lab var			seed_type "Traditional/improved"
	lab var			intrcrp "=1 if intercropped"
	lab var			area_plnt "Total area of plot planted"
	lab var			prct_plnt "Percent planted to crop"
					
	isid			hhid prcid pltid cropid	cropid2
		
	order			hhid prcid pltid cropid cropid2 plnt_month plnt_year intrcrp
	
	compress


* save file
	save 			"$export/2015_agsec4a.dta", replace

* close the log
	log	close

/* END */	
