* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 hh shocks (gsec16)
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
	global root 	"$data/raw_lsms_data/uganda/wave_8/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_8"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_gsec16_plt", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec16.dta", clear
	
* list shock types	
	describe 		s16qa01
	label list 		shocksRoster__id
	
* create indicator variable for ag shocks 
	gen 			ag_shck = 1 if s16qa01 == 1 & (s16qa01 < 108 | s16qa01 > 1000)
	replace 		ag_shck = 0 if ag_shck ==.

* create indicator variable for hh shocks 
	gen 			hh_shck = 1 if s16qa01 == 1 & (s16qa01 > 107 & s16qa01 < 1000)
	replace 		hh_shck = 0 if hh_shck ==.
	
* collapse to household	
	collapse 		(max) ag_shck hh_shck , by(hhid)
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	lab var			ag_shck "=1 if agricultural shock"
	lab var			hh_shck "=1 if household shock"
	
	isid			hhid
	recast 			str32 hhid
	 
	compress
	
* save file 
	save 			"$export/2019_gsec16.dta", replace	
	
* close the log
	log	close

/* END */
	


	
