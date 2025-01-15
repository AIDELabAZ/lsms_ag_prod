* Project: LSMS_ag_prod 
* Created on: March 2024
* Created by: alj
* Edited on: 11 November 2024
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
	global		root 	= 	"$data/raw_lsms_data/malawi/wave_6/raw"	
	global		export 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/wave_6"
	global		logout 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"$logout/mwi_hh_mod_b19", append

* **********************************************************************
* 1 - clean person traits 
* **********************************************************************

* load data
	use 			"$root/hh_mod_b_19.dta", clear

* rename variables			
	rename 			hh_b03 gender
	rename 			hh_b05a age
	
* for reece 
* gender of houeshold head 

	gen 			hh_head_gender = . 
	replace			hh_head_gender = gender if hh_b04 == 1
	bys y4_hhid: 	egen hh_head_gender_all = max(hh_head_gender)
	replace			hh_head_gender = hh_head_gender_all if hh_head_gender == .
	
***********************************************************************
** 2 - output person data for merge with ag
***********************************************************************
	
	keep 			y4_hhid PID id_code gender age hh_head_gender
	
	order			y4_hhid PID id_code gender age hh_head_gender

	
compress
	describe
	summarize 
	
* save data
	save 			"$export/hh_mod_b_19.dta", replace
	
* close the log
	log	close

/* END */
	