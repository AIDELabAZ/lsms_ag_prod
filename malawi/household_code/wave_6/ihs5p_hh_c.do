* Project: LSMS_ag_prod 
* Created on: March 2024
* Created by: alj
* Edited on: 7 November 2024
* Edited by: alj 
* Stata v.18.5 

* does
	* cleans basic information 

* assumes
	* access to MWI 6 raw data - PANEL
	
* TO DO:
	* done  

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/raw_lsms_data/malawi/wave_6/raw"	
	loc		export 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/wave_6"
	loc		logout 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_hh_mod_b19", append

* **********************************************************************
* 1 - clean plot area 
* **********************************************************************

* load data
	use 			"`root'/hh_mod_c_19.dta", clear
		
* rename variables			
	rename			hh_c08 edu
	
	replace			edu = 1 if edu != . 
	replace			edu = 0 if edu == .
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			y4_hhid id_code edu
	
	order			y4_hhid id_code edu
	
	compress
	
* save file 
	save 			"$`export'/hh_mod_c_19.dta", replace	
	
* close the log
	log	close

/* END */