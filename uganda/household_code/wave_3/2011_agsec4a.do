* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 29 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 3 crops grown and seed (2011_AGSEC4A) for the 1st season
	* questionaire 4B is for 2nd season
	* cleans
		* planting date
		* seeds
		* crops
	* output cleaned seed and planting date file

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* find the unique identifier
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_agsec4a_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/2011_AGSEC4A.dta", clear
	
* rename variables	
	rename 			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename 			Crop_Other1 cropid2
	rename			a4aq11b unit
	rename			a4aq11a seed
	rename 			a4aq13 seed_type
	rename 			a4aq7 area_plnt
	rename			a4aq9 prct_plnt
	rename			Crop_Planted_Month plnt_month
	rename			Crop_Planted_Year plnt_year
	
* change format 
	format			hhid %16.0g
	sort 			hhid prcid pltid cropid  
	
	mdesc 			hhid prcid pltid prcid 
	* we have 5 obs missing pltid and cropid
	drop if			pltid ==.
	* 5 observations dropped

	*isid 			hhid prcid pltid cropid	 
	*** these variables are not a unique identifier
	
* make a variable that shows if intercropped or not
	gen				intrcrp = 1 if a4aq8 == 2
	replace			intrcrp = 0 if intrcrp ==.

* drop cropid is annual, other, fallow, pasture, and trees
	drop 			if cropid > 699
	*** 2,479 observations deleted 
	
***********************************************************************
**# 2 - percentage planted 	
***********************************************************************
	
* convert area to hectares 
	replace 		area_plnt = area_plnt * 0.404686
	
* create variable for percentage of plot area 
	replace			prct_plnt = prct_plnt / 100
	
	gen 			crop_area = area_plnt * prct_plnt
	label var		crop_area "Area planted (ha)"



***********************************************************************
**# 3 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type, missing 
	* 6,035 used traditional
	* 705 used improved
	* 1,714 missing
	* missing is mostly tubers

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4aq3 == 1
	replace			seed_any = 0 if seed_any ==.
	tab 			seed_any
	* 67.42 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			L_Unit_Code
	
	gen 				seed_qty = .
	label var			seed_qty "Seed used (kg)"
	
	*kgs
		replace 		seed_qty = seed if unit == 1
		*** 4,219  changes
		count if 		unit == 1 & seed_qty ==1 
		*** 369 observations  
		
	* grams 
		replace 		seed_qty= seed/1000 if unit == 2 
		*** 55 changes 
		*** check values, observations less than 1kg
		
	* sack 120 kgs
		replace			seed_qty = seed * 120 if unit == 9
		*** 124 changes  
		
	* sack 100 kgs 
		replace 		seed_qty = seed * 100 if unit == 10
		*** 236 changes 
		
	* sack 80 kgs 
		replace 		seed_qty = seed * 80 if unit == 11
		***  52 changes 	

	* sack 50 kgs 
		replace 		seed_qty = seed * 50 if unit == 12
		***  52 changes 
		
	* Tin 20 lts
		replace 		seed_qty = seed * 20 if unit == 20
		***  71 changes 	

	* Tins 5 lts 
		replace 		seed_qty = seed * 5 if unit == 21
		***  14 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty = seed * 15 if unit == 22
		***  282 changes
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty = seed * 2 if unit == 29
		***  96 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty = seed * 1 if unit == 30
		***  52 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty = seed * 0.5 if unit == 31
		***  668 changes 
		
	* basket 20 kg
		replace 		seed_qty = seed * 20 if unit == 37
		***  33 changes 

	* basket 10 kg
		replace 		seed_qty = seed * 10 if unit == 38
		***  7 changes 
		
	* basket 5 kg
		replace 		seed_qty = seed * 5 if unit == 39
		***  12 changes 

	* basket 2 kg
		replace 		seed_qty = seed * 2 if unit == 40
		***  21 changes 
			
	
	
* summarize seed quantity
	sum				seed_qty
	*** min 0.000001 
	*** max 33,330
	
	mdesc 			seed_qty
	*** 2,462 missing 
	
	tab 			seed_qty if seed_any == 0
	*** no quanty if hh did not use seed
	
		
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
					
					
	collapse		(sum) seed_qty /// 
					(mean) plnt_month plnt_year, ///
					by (hhid prcid cropid pltid intrcrp seed_type crop_area /// 
					area_plnt prct_plnt)
					
	duplicates 		drop hhid prcid pltid cropid, force
	
	isid			hhid prcid pltid cropid	
		
	order			hhid prcid pltid cropid  plnt_month plnt_year intrcrp
	
	compress


* save file
	save 			"$export/2011_agsec4a.dta", replace
	
* close the log
	log	close

/* END */	
