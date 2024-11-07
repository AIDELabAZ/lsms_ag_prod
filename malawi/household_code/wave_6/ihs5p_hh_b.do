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
	use 			"`root'/hh_mod_b_19.dta", clear

	* rename variables			
	rename 			hh_b03 gender
	rename 			hh_b05a age
	
***********************************************************************
** 2 - output person data for merge with ag
***********************************************************************
	
	keep 			y4_hhid PID id_code gender age 
	
	order			y4_hhid PID id_code gender age 

	
compress
	describe
	summarize 
	
* save data
	save 			"`export'/hh_mod_b_19.dta", replace
	
* close the log
	log	close

/* END */
	