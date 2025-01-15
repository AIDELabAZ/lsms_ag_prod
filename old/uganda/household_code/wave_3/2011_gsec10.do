* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 29 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 3 hh energy use (gsec10)
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
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_gsec10_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC10A.dta", clear
	
	sort 			HHID
	isid 			HHID
	
* create variable hhid long
	destring		HHID, gen(hhid)
	format %		16.0g 	hhid

	
* generate indicator variable for electricity
	gen 			electric = 1 if h10q1 == 1
	replace			electric = 0 if electric ==.
	lab var			electric "=1 if household has electricity"
	

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid electric
	
* save file 
	save 			"$export/2011_gsec10.dta", replace	
	
* close the log
	log	close

/* END */
	


	
