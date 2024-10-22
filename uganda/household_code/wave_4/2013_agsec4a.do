* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
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
	
* rename variables	
	rename 			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid
	rename 			cropID cropid
	rename			a4aq11b unit
	rename			a4aq11a seed_qty
	rename 			a4aq13 seed_type
	rename 			a4aq7 area_plntd
	rename			a4aq9 prct_plntd
	rename			a4aq9_1 mnth_plntd
	rename			a4aq9_2 year_plntd
	
	sort 			hhid prcid pltid cropid  
	
	mdesc 			hhid prcid pltid pltid 
	* we have 1 obs missing pltid and cropid
	
	drop if			pltid ==. | prcid ==.
	* 1 observations dropped

	isid 			hhid prcid pltid cropid	
	
* make a variable that shows if intercropped or not
	gen				intrcrp = 1 if a4aq8 == 2
	replace			intrcrp = 0 if intrcrp ==.

	
***********************************************************************
**# 2 - percentage planted 	
***********************************************************************

* convert area to hectares 
	replace 		area_plntd = area_plntd * 0.404686
	
* create variable for percentage of plot area
	replace 		prct_plntd = prct_plntd / 100
	
	gen 			crop_area = area_plntd * prct_plntd
	label var 		crop_are "Area planted (ha)"
	
	
***********************************************************************
**# 3 - merge kg conversion file and create seed quantity
***********************************************************************

* see how many hh used traditional vs improved seed 
	tab 			seed_type, missing
	* 6,139 used traditional
	* 598 used improved
	* 3,812 missing
	* missing is mostly banana or tubers

* create a variable showing used of seed 
	gen 			seed_any = 1 if a4aq16 == 1
	replace			seed_any = 0 if seed_any == .
	tab				seed_any
	* 63.9 % used seed

* convert seed_qty to kgs 
	tab					unit
	describe			unit
	label list 			a4aq11b
	
	gen 				seed_qty_kg = . 
	label var			seed_qty_kg "Seed used (kg)"
	
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
**# 4 - create seed price 
***********************************************************************	
	
* generate a variable showing seed purchase
	gen				seed_purch = 1 if a4aq10 == 1
	replace 		seed_purch = 0 if seed_purch == .
	tab 			seed_purch
	* 20.12% purchased seeds

* purchase value 
	rename 			a4aq15 seed_vle
	
* generate variable for seed price
	gen 			seed_price = seed_vle / seed_qty_kg
	label var		seed_price "Price of seed (shillings/kg)"
	
	sum				seed_price
	count if 		seed_price == . & seed_purch == 1
	*** 247 hh who purchased but are missing price 
	*** 1 missing seed value
	
		
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************

	keep 			hhid prcid cropid pltid intrcrp seed_qty_kg ///
						seed_type seed_vle seed_price crop_area ///
						mnth_plntd year_plntd

	lab var			seed_type "Traditional/improved"
	lab var			seed_vle "Value of purchased seed (shilling)"
	lab var			intrcrp "=1 if intercropped"
					
	isid			hhid prcid pltid cropid	
		
	order			hhid prcid pltid cropid	mnth_plntd year_plntd intrcrp
	
	compress


* save file
	save 			"$export/2013_agsec4a.dta", replace

* close the log
	log	close

/* END */	
