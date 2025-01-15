* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 23 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 hh shocks (gsec16)
	* cleans
		* household shock dummy
		* agricultural shock dummy
	* outputs household file for merging

* assumes
	* access to raw data

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
	log using 		"$logout/2013_gsec16_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec16.dta", clear
	
* rename variables
	rename			HHID hhid
	
* list shock types
	label list 		h16q00
	
* create indicator variable for ag shocks 
	gen 			ag_shck = 1 if h16q01 == 1 & (h16q00 < 108 | h16q00 > 1000)
	replace 		ag_shck = 0 if ag_shck ==.

* create indicator variable for hh shocks 
	gen 			hh_shck = 1 if h16q01 == 1 & (h16q00 > 107 & h16q00 < 1000)
	replace 		hh_shck = 0 if hh_shck ==.
	
* collapse to household	
	collapse 		(max) ag_shck hh_shck , by(hhid)
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	lab var			ag_shck "=1 if agricultural shock"
	lab var			hh_shck "=1 if household shock"
	
	isid			hhid
	
	compress
	
* save file 
	save 			"$export/2013_gsec16.dta", replace	
	
* close the log
	log	close

/* END */
	


	
