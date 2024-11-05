* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 hh information (gsec4)
	* cleans househod member characteristics
		* education
	* outputs file for merging with plot owner (agsec2a and agsec2b)

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
	log using 		"$logout/2019_gsec4", append
	
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec4.dta", clear
	
* rename variables			
	rename			s4q07 edu
	describe 		edu
	label list 		s4q07

	isid 			hh pid
	
	replace			edu = 1 if edu != . & edu !=98
	replace			edu = 0 if edu == . | edu == 98
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid  pid edu
	
	order			hhid  pid edu
	
	lab var			pid "Person ID"
	
	compress
	
* save file 
	save 			"$export/2019_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
