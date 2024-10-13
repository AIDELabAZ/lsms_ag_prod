* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 12 Oct 2024
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
	* last section
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_5/raw"  
	global export 	"$data/household_data/uganda/wave_5/refined"
	global logout 	"$data/household_data/uganda/logs"
	
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
	rename 			a4bq13 seed_type
	
	sort 			hhid prcid pltid cropid cropid2 
	
	mdesc 			hhid prcid pltid cropid cropid2
	* we have 5 obs missing pltid and 1 cropid
	drop if			pltid ==. | cropid ==.
	* 6 observations dropped

	isid 			hhid prcid pltid cropid	cropid2


	
***********************************************************************
**# 2 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type
	* 5,359 used traditional
	* 439 used improved
	* 3,887 missing 

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4bq16 == 1
	replace			seed_any = 0 if seed_any ==.
	* 61 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			a4bq11b
	
	gen 				seed_qty_kg =. 
	label var			seed_qty_kg "quanity of seeds used (kg)"
	
	*kgs
		replace 		seed_qty_kg = seed_qty if unit == 1
		*** 4,008  changes
		count if 		unit == 1 & seed_qty ==1 
		*** 2 observations  
		
	* grams 
		replace 		seed_qty_kg = seed_qty/1000 if unit == 2 
		*** 55 changes 
		*** check values, observations with 1,2,8, 0.25 grams
		
	* sack 120 kgs
		replace			seed_qty_kg = seed_qty * 120 if unit == 9
		*** 12 changes  
		
	* sack 100 kgs 
		replace 		seed_qty_kg = seed_qty * 100 if unit == 10
		*** 272 changes 
		
	* sack 80 kgs 
		replace 		seed_qty_kg = seed_qty * 80 if unit == 11
		***  121 changes 	

	* sack 50 kgs 
		replace 		seed_qty_kg = seed_qty * 50 if unit == 12
		***  52 changes 
		
	* Tin 20 lts
		replace 		seed_qty_kg = seed_qty * 20 if unit == 20
		***  101 changes 	

	* Tins 5 lts 
		replace 		seed_qty_kg = seed_qty * 5 if unit == 21
		***  6 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty_kg = seed_qty * 15 if unit == 22
		***  314 changes
		count if 		seed_qty == . & unit == 22
		*** 1 missing 
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty_kg = seed_qty * 2 if unit == 29
		***  52 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty_kg = seed_qty * 1 if unit == 30
		***  23 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty_kg = seed_qty * 0.5 if unit == 31
		***  125 changes 
		
	* basket 20 kg
		replace 		seed_qty_kg = seed_qty * 20 if unit == 37
		***  2 changes 

	* basket 10 kg
		replace 		seed_qty_kg = seed_qty * 10 if unit == 38
		***  4 changes 
		
	* basket 5 kg
		replace 		seed_qty_kg = seed_qty * 5 if unit == 39
		***  20 changes 

	* basket 2 kg
		replace 		seed_qty_kg = seed_qty * 2 if unit == 40
		***  3 changes 
			
	
	
* summarize seed quantity
	sum				seed_qty_kg
	*** min 0.00025 
	*** max 9000 
	
	mdesc 			seed_qty_kg
	

***********************************************************************
**# 3 - create seed price 
***********************************************************************	
	
* generate a variable showing seed purchase
	gen				seed_purch = 1 if a4bq10 ==1
	replace 		seed_purch = 0 if seed_purch ==.
	tab 			seed_purch
	* 15.91% purchased seeds

* purchase value 
	rename 			a4bq15 seed_vle
	
* generate variable for seed price
	gen 			seed_price = seed_vle / seed_qty_kg
	label var		seed_price "price of seed per kg (shillings)"
	
	sum				seed_price
	count if 		seed_price == . & seed_purch == 1
	*** 183 hh who purchased but are missing price 
	*** 7 missing seed value
	*** 
	
	
***********************************************************************
**# 4 - type of crop stand
***********************************************************************

* make a variable that shows if intercropped or not
	gen				intrcrp_any =1 if a4bq8 == 2
	replace			intrcrp_any = 0 if intrcrp_any ==.

* variable for use of seeds
	gen				seeds_any = 1 if a4bq16 ==1
	replace			seeds_any = 0 if a4bq16 ==.
	
	
	
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************

	keep 			hhid hh_agric prcid cropid cropid2 cropid3 ///
					pltid intrcrp_any seed_qty_kg seed_type seed_vle seed_price

	compress
	describe
	summarize

* save file
	save 			"$export/2015_agsec4a_plt.dta", replace

* close the log
	log	close

/* END */	
