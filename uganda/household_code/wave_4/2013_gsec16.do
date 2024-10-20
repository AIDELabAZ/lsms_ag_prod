* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 19 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* create indicator variables for shocks (agricultural and hh)
	* reads Uganda wave 4 hh information (gsec16)

* assumes
	* access to raw data
	* mdesc.ado

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
	rename 			h16q00 shocks
	describe 		shocks
	label list 		h16q00
	
* create indicator variable for agricultural season shocks (flood, fire, drought, 
/// irregular rains)

	gen 			ag_shock = 1 if shocks == 102 | shocks == 117 | shocks == 1011 
	replace 		ag_shock = 0 if ag_shock ==.

* create indicator variable for hh shocks 
	gen 			hh_shock = 1 if shocks == 112 | shocks == 113
	replace 		hh_shock = 0 if hh_shock ==.
	
* modify format of pid so it matches pid from other files 
	gen 			hhid = substr(HHID, 2, 5) + substr(HHID, 8,2) + substr(HHID, 11, 2)
	destring		hhid, replace
	

	keep 			hhid  ag_shock hh_shock
	order 			hhid, after(ag_shock)
	order 			ag_shock, after(hhid)
	
	collapse 		(max) ag_shock (max) hh_shock , by(hhid)
	format 			hhid %16.0g
	
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	
* save file 
	save 			"$export/2013_gsec16_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
