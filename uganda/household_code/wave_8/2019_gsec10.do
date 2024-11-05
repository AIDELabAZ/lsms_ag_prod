* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 hh energy use (gsec10)
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
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_gsec10_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec10_1.dta", clear
	
	
* generate indicator variable for electricity
	gen 			electric = 1 if s10q01 == 1
	replace			electric = 0 if electric ==.
	lab var			electric "=1 if household has electricity"
	
	recast 			str32 hhid
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid electric
	
* save file 
	save 			"$export/2019_gsec10.dta", replace	
	
* close the log
	log	close

/* END */
	


	
