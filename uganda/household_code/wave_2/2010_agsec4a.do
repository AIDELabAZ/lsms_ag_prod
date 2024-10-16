* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* seed use
	* reads Uganda wave 2 crops grown and types of seeds info (AGSEC4A) for the 1st season
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
	global root 	"$data/household_data/uganda/wave_2/raw"  
	global export 	"$data/household_data/uganda/wave_2/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_agsec4a_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/2010_AGSEC4A.dta", clear
	
* rename variables	
	rename 			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename 			cropID_other cropid2
	rename			a4aq11b unit
	rename			a4aq11a seed_qty
	rename 			a4aq13 seed_type
	
	sort 			hhid prcid pltid cropid  
	
	mdesc 			hhid prcid pltid pltid 
	* we have 1 obs missing pltid and cropid
	drop if			pltid ==. | prcid ==.
	* 1 observations dropped

	isid 			hhid prcid pltid cropid	


	
***********************************************************************
**# 2 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type
	* 6,139 used traditional
	* 598 used improved
	* 3,812 missing 

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4aq16 == 1
	replace			seed_any = 0 if seed_any ==.
	* 63.9 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			a4aq11b
	
	gen 				seed_qty_kg =. 
	label var			seed_qty_kg "quanity of seeds used (kg)"
	
	*kgs
		replace 		seed_qty_kg = seed_qty if unit == 1
		*** 4,165  changes
		count if 		unit == 1 & seed_qty ==1 
		*** 392 observations  
		
	* grams 
		replace 		seed_qty_kg = seed_qty/1000 if unit == 2 
		*** 68 changes 
		*** check values, observations with 1,2,8, 0.25 grams
		
	* sack 120 kgs
		replace			seed_qty_kg = seed_qty * 120 if unit == 9
		*** 59 changes  
		
	* sack 100 kgs 
		replace 		seed_qty_kg = seed_qty * 100 if unit == 10
		*** 318 changes 
		
	* sack 80 kgs 
		replace 		seed_qty_kg = seed_qty * 80 if unit == 11
		***  70 changes 	

	* sack 50 kgs 
		replace 		seed_qty_kg = seed_qty * 50 if unit == 12
		***  79 changes 
		
	* Tin 20 lts
		replace 		seed_qty_kg = seed_qty * 20 if unit == 20
		***  126 changes 	

	* Tins 5 lts 
		replace 		seed_qty_kg = seed_qty * 5 if unit == 21
		***  69 changes 
		
	* plastic basin 15 lts 
		replace 		seed_qty_kg = seed_qty * 15 if unit == 22
		***  341 changes
		
	* kimbo/cowboy/blueland tin (2kg)
		replace 		seed_qty_kg = seed_qty * 2 if unit == 29
		***  125 changes 
		
	* kimbo/cowboy/blueland tin (1kg)
		replace 		seed_qty_kg = seed_qty * 1 if unit == 30
		***  29 changes 

	* kimbo/cowboy/blueland tin (0.5kg)
		replace 		seed_qty_kg = seed_qty * 0.5 if unit == 31
		***  182 changes 
		
	* basket 20 kg
		replace 		seed_qty_kg = seed_qty * 20 if unit == 37
		***  5 changes 

	* basket 10 kg
		replace 		seed_qty_kg = seed_qty * 10 if unit == 38
		***  12 changes 
		
	* basket 5 kg
		replace 		seed_qty_kg = seed_qty * 5 if unit == 39
		***  27 changes 

	* basket 2 kg
		replace 		seed_qty_kg = seed_qty * 2 if unit == 40
		***  25 changes 
			
	
	
* summarize seed quantity
	sum				seed_qty_kg
	*** min 0.001 
	*** max 38,400
	
	mdesc 			seed_qty_kg
	

***********************************************************************
**# 3 - create seed price 
***********************************************************************	
	
* generate a variable showing seed purchase
	gen				seed_purch = 1 if a4aq10 ==1
	replace 		seed_purch = 0 if seed_purch ==.
	tab 			seed_purch
	* 20.12% purchased seeds

* purchase value 
	rename 			a4aq15 seed_vle
	
* generate variable for seed price
	gen 			seed_price = seed_vle / seed_qty_kg
	label var		seed_price "price of seed per kg (shillings)"
	
	sum				seed_price
	count if 		seed_price == . & seed_purch == 1
	*** 247 hh who purchased but are missing price 
	*** 1 missing seed value
	
	
***********************************************************************
**# 4 - type of crop stand
***********************************************************************

* make a variable that shows if intercropped or not
	gen				intrcrp_any =1 if a4aq8 == 2
	replace			intrcrp_any = 0 if intrcrp_any ==.

		
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************

	keep 			hhid prcid cropid cropid2  ///
					pltid intrcrp_any seed_qty_kg seed_type seed_vle seed_price

	compress
	describe
	summarize

* save file
	save 			"$export/2013_agsec4a_plt.dta", replace

* close the log
	log	close

/* END */	
