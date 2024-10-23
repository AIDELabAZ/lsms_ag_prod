* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 crops grown and seed (2013_AGSEC4A) for the 1st season
	* questionaire 4B is for 2nd season
	* cleans
		* planting date
		* seeds
		* crops
	* output cleaned seed and planting date file

* assumes
	* access to the raw data
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
	cap log 		close
	log using 		"$logout/2013_agsec4a_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/agric/AGSEC4A.dta", clear
	
* order and rename variables
	order			hh
	drop			wgt_X

	rename			hh hhid
	rename			HHID hh
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename			a4aq11b unit
	rename			a4aq11a seed
	rename 			a4aq13 seed_type
	rename 			a4aq7 area_plnt
	rename			a4aq9 prct_plnt
	rename			a4aq9_1 plnt_month
	rename			a4aq9_2 plnt_year
	
	mdesc 			hhid prcid pltid pltid 
	* we have 1 obs missing pltid and cropid
	
	drop if			pltid ==. | prcid ==.
	* 1 observations dropped

	isid 			hhid prcid pltid cropid	
	
* make a variable that shows if intercropped or not
	gen				intrcrp = 1 if a4aq8 == 2
	replace			intrcrp = 0 if intrcrp ==.

* drop cropid is annual, other, fallow, pasture, and trees
	drop 			if cropid > 699
	*** 2,357 observations deleted 
	
***********************************************************************
**# 2 - percentage planted 	
***********************************************************************

* convert area to hectares 
	replace 		area_plnt = area_plnt * 0.404686
	
* create variable for percentage of plot area
	replace 		prct_plnt = prct_plnt / 100
	
	gen 			crop_area = area_plnt * prct_plnt
	label var 		crop_area "Area planted (ha)"
	
	
***********************************************************************
**# 3 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type, missing
	* 5,977 used traditional
	* 577 used improved
	* 1,638 missing
	* missing is mostly tubers

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4aq16 == 1
	replace			seed_any = 0 if seed_any == .
	tab				seed_any
	* 80 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			a4aq11b
	
	gen 				seed_qty = . 
	label var			seed_qty "Seed used (kg)"
	
	*kgs
		replace 		seed_qty = seed
		*** 4,144  changes
		count if 		unit == 1 & seed ==1 
		*** 388 observations  
		
	* grams 
		replace 		seed_qty = seed/1000 if unit == 2 
		*** 59 changes 
		*** check values, observations with 1,2,8, 0.25 grams
		
	* sack 120 kgs
		replace			seed_qty = seed * 120 if unit == 9
		*** 58 changes  
		
	* sack 100 kgs 
		replace 		seed_qty = seed * 100 if unit == 10
		*** 318 changes 
		
	* sack 80 kgs 
		replace 		seed_qty = seed * 80 if unit == 11
		***  70 changes 	

	* sack 50 kgs 
		replace 		seed_qty = seed * 50 if unit == 12
		***  79 changes 
		
	* Tin 20 lts
		replace 		seed_qty = seed * 20 if unit == 20
		***  126 changes 	

	* Tins 5 lts 
		replace 		seed_qty = seed * 5 if unit == 21
		***  66 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty = seed * 15 if unit == 22
		***  339 changes
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty = seed * 2 if unit == 29
		***  123 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty = seed * 1 if unit == 30
		***  28 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty = seed * 0.5 if unit == 31
		***  180 changes 
		
	* basket 20 kg
		replace 		seed_qty = seed * 20 if unit == 37
		***  5 changes 

	* basket 10 kg
		replace 		seed_qty = seed * 10 if unit == 38
		***  12 changes 
		
	* basket 5 kg
		replace 		seed_qty = seed * 5 if unit == 39
		***  27 changes 

	* basket 2 kg
		replace 		seed_qty = seed * 2 if unit == 40
		***  25 changes 
	
* summarize seed quantity
	sum				seed_qty
	*** min 0.001 
	*** max 38,400
	
	mdesc 			seed_qty
	* 1,635 missing
	
	tab				seed_qty if seed_any == 0
	* no qty if didn't use seed
		
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************

	keep 			hhid hh prcid cropid pltid intrcrp seed_qty ///
						seed_type crop_area plnt_month plnt_year

	lab var			seed_type "Traditional/improved"
	lab var			intrcrp "=1 if intercropped"
					
	isid			hhid prcid pltid cropid	
		
	order			hhid hh prcid pltid cropid plnt_month plnt_year intrcrp
	
	compress


* save file
	save 			"$export/2013_agsec4a.dta", replace

* close the log
	log	close

/* END */	
