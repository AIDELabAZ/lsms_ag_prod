* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 1 hh energy use (gsec10)
	* cleans
		* electricity dummy
	* outputs household file for merging

* assumes
	* access to raw data

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_gsec10_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/2009_GSEC10A.dta", clear
	
* rename variables
	rename			HHID hhid
	
* generate indicator variable for electricity
	gen 			electric = 1 if h10q1 == 1
	replace			electric = 0 if electric ==.
	lab var			electric "=1 if household has electricity"
	

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid electric
	
* save file 
	save 			"$export/2009_gsec10.dta", replace	
	
* close the log
	log	close

/* END */
	


	
