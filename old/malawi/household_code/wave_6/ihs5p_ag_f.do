* Project: LSMS_ag_prod 
* Created on: March 2024
* Created by: alj
* Edited on: 7 November 2024
* Edited by: alj 
* Stata v.18.5 

* does
	* nothing 
	* do not use this file - created because fertilizer questions are asked in like 1000 places 
	
* assumes
	* access to MWI W6 raw data
	
* TO DO:
	* everything
	
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
	use 			"`root'/ag_mod_f_19.dta", clear

	
	describe 
	sort 			y4_hhid gardenid plotid 	
	capture 		: noisily : isid y4_hhid gardenid plotid
	*** some are missing?
	duplicates 		report y4_hhid gardenid plotid 
	*** none

	
***********************************************************************
** 2 - fertilizer
***********************************************************************

/* END */	