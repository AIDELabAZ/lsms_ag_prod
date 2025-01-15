* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 29 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 3 hh shocks (gsec16)
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
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_gsec16_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC16.dta", clear
	
	sort 			HHID
	
* create variable hhid long
	destring		HHID, gen(hhid)
	format %		16.0g 	hhid
	
* list shock types
	describe		h16q00
	label list 		df_SHOCK
	
* create indicator variable for ag shocks 
	gen 			ag_shck = 1 if h16q01 == 1 & h16q00 < 108
	replace 		ag_shck = 0 if ag_shck ==.

* create indicator variable for hh shocks 
	gen 			hh_shck = 1 if h16q01 == 1 & h16q00 > 107
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
	save 			"$export/2011_gsec16.dta", replace	
	
* close the log
	log	close

/* END */
	


	
