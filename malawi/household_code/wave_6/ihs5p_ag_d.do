* Project: LSMS_ag_prod 
* Created on: March 2024
* Created by: alj
* Edited on: 6 November 2024
*** A VERY BAD DAY 
* Edited by: alj 
* Stata v.18.5 
* does
	* cleans crop price / sales information 
	* directly follow from ag_d code - by JB
	
* assumes
	* access to MWI W6 raw data
	
* TO DO:
	* done
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/raw_lsms_data/malawi/wave_6/raw"	
	loc		export 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/wave_6"
	loc		logout 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/logs"
	loc 	temp 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/tmp"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_d_19", append


* **********************************************************************
* 1 - setup to clean plot  
* **********************************************************************

* load data
	use 			"`root'/ag_mod_d_19.dta", clear

	
	describe 
	sort 			y4_hhid gardenid plotid 	
	capture 		: noisily : isid y4_hhid gardenid plotid
	*** some are missing?
	duplicates 		report y4_hhid gardenid plotid 
	*** none

* **********************************************************************
* 2 -  drop tobacco 
* **********************************************************************	
	egen 			tobacco =  anymatch(ag_d20a ag_d20b ag_d20c ag_d20d ag_d20e), values(5/10) 
	drop			if tobacco == 1
	*** 223 observations 
	
	*** also drop trees? not seeing trees ... 
	
* **********************************************************************
* 3 - soil and erosion and slope and wetlands
* **********************************************************************

* bring in spatial variables for merge merge to conversion factor database
	merge m:1 y4_hhid using "`root'/hh_mod_a_filt_19.dta", keepusing(region district reside) assert(2 3) keep(3) nogenerate
	*** (all) 5347 matched
	
* cut all code for soil and erosion - not used 	
	
* **********************************************************************
* 4 - fertilizer
* **********************************************************************

* organic 
* binary 
	tab 			ag_d36
	gen				fert_org = 1 if ag_d36 == 1
	replace			fert_org = 0 if fert_org == . 

* inorganic
	tab 			ag_d38
	describe 		ag_d38*
	tabstat 		ag_d39a ag_d39b ag_d39d ag_d39e ag_d39f ag_d39g ag_d39i ag_d39j, by(ag_d38) statistics(n mean) columns(statistics) longstub format(%9.3g)
	
* as an intermediate step, make dummies for non-missing type and quantity 
* details for a first application and second application. 
	generate 		fert_inorg1 = (!missing(ag_d39a) & !missing(ag_d39c) & !missing(ag_d39c))	
	*** type, quantity and unit for first application are non-missing
	generate 		fert_inorg2 = (!missing(ag_d39f) & !missing(ag_d39g) & !missing(ag_d39h))	
	*** type, quantity and unit for second application are non-missing
	
	gen 			fertkgs_con = .
	replace			fertkgs_con = 0.0001 if  ag_d39c == 1 
	replace			fertkgs_con = 1 if ag_d39c == 2
	replace			fertkgs_con = 2 if ag_d39c == 3
	replace			fertkgs_con = 3 if ag_d39c == 4
	replace			fertkgs_con = 5 if ag_d39c == 5
	replace 		fertkgs_con = 10 if ag_d39c == 6
	replace			fertkgs_con = 50 if ag_d39c == 7 
	
	gen 			fert_inorg_kg1 =  ag_d39c * fertkgs_con
	replace 		fert_inorg_kg1 = 0 if fert_inorg_kg1 == . 
	gen 			fert_inorg_kg2 =  ag_d39f * fertkgs_con
	replace 		fert_inorg_kg2 = 0 if fert_inorg_kg2 == . 
	egen 			fert_inorg_kg = rsum(fert_inorg_kg1 fert_inorg_kg2)

	generate 		fert_inorg_any = (fert_inorg1==1 | fert_inorg2==1)
	label 			variable fert_inorg_any	"inorganic fertilizer was applied on plot"

	egen 			fert_inorg_n = rowtotal(fert_inorg1 fert_inorg2)
	label 			variable fert_inorg_n "number of applications of inorganic fertilizer on plot"

	drop 			fert_inorg1 fert_inorg2 fert_inorg_kg1 fert_inorg_kg2
	
* fert any 	
	rename 			ag_d39d fert_qty1
	rename			ag_d39j fert_qty2
	generate		fert_any = 1 if fert_qty1 != . 
	replace 		fert_any = 0 if fert_qty1 == 0 
	replace			fert_any = 1 if fert_qty2 != . 
	replace 		fert_any = 0 if fert_qty2 == 0
	tab 			fert_any 
	*** 47 percent use some nonzero amount of fertilizer 
	
* fert kgs 
	egen 			fert_qty = rowtotal(fert_qty1 fert_qty2)

* replace the missing fert_any with 0
	tab 			fert_qty if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 0 changes
			
	sum 			fert_qty if fert_any == 1, detail
	*** mean 60.50, min 0.5, max 5,000
	
* **********************************************************************
* 5 - irrigation
* **********************************************************************
	
	tabulate 		ag_d28a ag_d28b, missing
	tabulate 		ag_d28_oth 
	egen 			irrigation_any = anymatch(ag_d28a ag_d28b), values(1 2 3 4 5 6 8) 
	replace			irrigation_any = 0 if ag_d28a == 7
	label 			variable irrigation_any	"plot has any system of irrigation" 

* **********************************************************************
* 6 - pesticide, insecticide, fungicide 
* **********************************************************************

* pesticide, disaggregating by type (insecticide, herbicide, fungicide) 
	tabulate 		ag_d40, missing
	describe 		ag_d41*
	tabulate 		ag_d41a, missing
	tabulate 		ag_d41a_oth if ag_d41a=="OTHER PESTICIDE/HERBICIDE(SPECIFY)":AG_D35A
	recode 			ag_d41a (11=8) if inlist(ag_d41a_oth,"2.4D","BULLET","ROUNDUP")
	summarize 		ag_d41b ag_d41c 

* dummies for use of one of three pesticide types 
	generate 		insecticide_any =	((ag_d41a == 7 & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 7 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable insecticide_any "insecticide was applied on plot" 
	generate 		herbicide_any =	((ag_d41a == 8 & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 8 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable herbicide_any "herbicide was applied on plot" 
	generate 		fungicide_any =	((ag_d41a == 9  & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 9 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable fungicide_any "fungicide was applied on plot" 

* make overall pesticide dummy, which also includes fumigants and 'other, specify' types 
	generate 		pesticide_any =	((!missing(ag_d41a) & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (!missing(ag_d41e) & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable pesticide_any	"any pesticide was applied on plot" 
	
* **********************************************************************
* 7 - labor days
* **********************************************************************

* family labor days
		describe 		ag_d42*	ag_d43* ag_d44* 
		*** includes land prep and planting; weeding, fertilizing, other non-harvest; and harvest 

* family labor during land prep / planting
		describe 		ag_d42*	
		generate 		famlbrdays1_1 = ag_d42b1*ag_d42c1	
		generate 		famlbrdays1_2 = ag_d42b2*ag_d42c2 	
		generate 		famlbrdays1_3 = ag_d42b3*ag_d42c3 	
		generate 		famlbrdays1_4 = ag_d42b4*ag_d42c4 	
		generate 		famlbrdays1_5 = ag_d42b5*ag_d42c5 	
		generate 		famlbrdays1_6 = ag_d42b6*ag_d42c6 	
		generate 		famlbrdays1_7 = ag_d42b7*ag_d42c7 	
		generate 		famlbrdays1_8 = ag_d42b8*ag_d42c8 	
		generate 		famlbrdays1_9 = ag_d42b9*ag_d42c9 	
		tabstat 		famlbrdays1_1 famlbrdays1_2 famlbrdays1_3 famlbrdays1_4 famlbrdays1_5 famlbrdays1_6 ///
							famlbrdays1_7 famlbrdays1_8 famlbrdays1_9  , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays1 = rowtotal(famlbrdays1_1 famlbrdays1_2 famlbrdays1_3 famlbrdays1_4 famlbrdays1_5 famlbrdays1_6 ///
							famlbrdays1_7 famlbrdays1_8 famlbrdays1_9 )
		
* family labor during weeding / fertilizing / other non-harvest activity	
		describe 		ag_d43*	
		generate 		famlbrdays2_1 = ag_d43b1*ag_d43c1	
		generate 		famlbrdays2_2 = ag_d43b2*ag_d43c2 	
		generate 		famlbrdays2_3 = ag_d43b3*ag_d43c3 	
		generate 		famlbrdays2_4 = ag_d43b4*ag_d43c4 	
		generate 		famlbrdays2_5 = ag_d43b5*ag_d43c5 	
		generate 		famlbrdays2_6 = ag_d43b6*ag_d43c6 	
		generate 		famlbrdays2_7 = ag_d43b7*ag_d43c7 	
		generate 		famlbrdays2_8 = ag_d43b8*ag_d43c8 	
		generate 		famlbrdays2_9 = ag_d43b9*ag_d43c9 	
		tabstat 		famlbrdays2_1 famlbrdays2_2 famlbrdays2_3 famlbrdays2_4 famlbrdays2_5 famlbrdays2_6 ///
							famlbrdays2_7 famlbrdays2_8 famlbrdays2_9 , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays2 = rowtotal(famlbrdays2_1 famlbrdays2_2 famlbrdays2_3 famlbrdays2_4 famlbrdays2_5 famlbrdays2_6 ///
							famlbrdays2_7 famlbrdays2_8 famlbrdays2_9 )

* family labor during harvest
		describe 		ag_d44* 	
		generate 		famlbrdays3_1 = ag_d44b1*ag_d44c1	
		generate 		famlbrdays3_2 = ag_d44b2*ag_d44c2 	
		generate 		famlbrdays3_3 = ag_d44b3*ag_d44c3 	
		generate 		famlbrdays3_4 = ag_d44b4*ag_d44c4 	
		generate 		famlbrdays3_5 = ag_d44b5*ag_d44c5 	
		generate 		famlbrdays3_6 = ag_d44b6*ag_d44c6 	
		generate 		famlbrdays3_7 = ag_d44b7*ag_d44c7 	
		generate 		famlbrdays3_8 = ag_d44b8*ag_d44c8 	
		generate 		famlbrdays3_9 = ag_d44b9*ag_d44c9 		
		tabstat 		famlbrdays3_1 famlbrdays3_2 famlbrdays3_3 famlbrdays3_4 famlbrdays3_5 famlbrdays3_6 ///
							famlbrdays3_7 famlbrdays3_8 famlbrdays3_9 , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays3 = rowtotal(famlbrdays3_1 famlbrdays3_2 famlbrdays3_3 famlbrdays3_4 famlbrdays3_5 famlbrdays3_6 ///
							famlbrdays3_7 famlbrdays3_8 famlbrdays3_9 )

* aggregate family labor 							
		egen 			famlbrdays = rowtotal(famlbrdays1 famlbrdays2 famlbrdays3)
		summarize 		famlbrdays, detail
		list 			y4_hhid plotid famlbrdays1 famlbrdays2 famlbrdays3 if famlbrdays>300
		*** does not address at this point in the code 
		*** somewhere in the neighbhorhood of 14 
				
* hired labor days
		describe 		ag_d47* ag_d48*
		*** includes non-harvest; and harvest 
		*** includes adult males, adult females, and children 

* hired labor during non-harvest 
		egen 			hirelbrdays2 = rowtotal(ag_d47a1 ag_d47a2 ag_d47a3)	
		tabstat 		hirelbrdays2, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		
* hired labor during harvest
		egen 			hirelbrdays3 = rowtotal(ag_d48a1 ag_d48a2 ag_d48a3)	
		tabstat 		hirelbrdays3, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		
* aggregate hired labor 
		egen 			hirelbrdays = rowtotal( hirelbrdays2 hirelbrdays3)
		summarize 		hirelbrdays, detail
		list 			y4_hhid plotid  hirelbrdays2 hirelbrdays3 if hirelbrdays>100
		***  2 total 
		list 			y4_hhid plotid  hirelbrdays2 hirelbrdays3 if hirelbrdays>150
		*** 2 total 
		
* total days of labor on all activities from all sources
		egen 			labordays = rowtotal(famlbrdays hirelbrdays)
		summarize 		labordays, detail
		list 			y4_hhid plotid famlbrdays hirelbrdays if labordays>300
		*** 15, issues mostly in familydays

* outlier checks without add'l information
		label 			variable labordays		"days of labor on plot" 

* hire labor dummy
	generate 			hirelabor_any = (hirelbrdays>0)
	label 				variable hirelabor_any	"any labor hired on plot" 
	
* add value of hired labor here
	adgaadsg
	ag_d47c ag_d48c 
	

		
***********************************************************************
** 8 - merge in manager characteristics
***********************************************************************	

* merge in age and gender for owner a
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 41 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner a	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 43 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_a
	rename			gender gender_mgmt_a
	rename			age age_mgmt_a
	rename			edu edu_mgmt_a
	
* rename pid for b to just pid so we can merge	
	rename			pid2 pid

* merge in age and gender for owner b
	merge m:1 		hhid pid using "$export/2013_gsec2.dta"
	* 3,080 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge

* merge in education for owner b	
	merge m:1 		hhid pid using "$export/2013_gsec4.dta"
	* 3,083 unmatched from master 
	
	drop 			if _merge == 2
	drop 			_merge
	
	rename 			pid manage_rght_b
	rename			gender gender_mgmt_b
	rename			age age_mgmt_b
	rename			edu edu_mgmt_b

	gen 			two_mgmt = 1 if manage_rght_a != . & manage_rght_b != .
	replace 		two_mgmt = 0 if two_mgmt ==.	


	
	

* **********************************************************************
* 8 - end matter, clean up to save
* **********************************************************************

	keep  			y4_hhid plotid gardenid crop_cash soiltype swc_* slope dambo irrigation_any fert_inorg_any ///
						fert_inorg_n insecticide_any herbicide_any fungicide_any pesticide_any labordays hirelabor_any fert_inorg_kg
	order 			y4_hhid plotid gardenid crop_cash soiltype swc_* slope dambo irrigation_any fert_inorg_any ///
						fert_inorg_n insecticide_any herbicide_any fungicide_any pesticide_any labordays hirelabor_any fert_inorg_kg

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_d_19.dta", replace

* close the log
	log			close

/* END */