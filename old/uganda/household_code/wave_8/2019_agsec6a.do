* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 4 Nov 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 8 livestock rosters (2019_AGSEC1)
	* this can also be found in agsec6a,b, and c
	* cleans indicators for ownership of
		* cattle and pack animals
		* small animals
		* poultry and rabbits
	* outputs single file with all three indicators

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
	log using 		"$logout/2019_agsec6a_plt", append
	
	
***********************************************************************
**# 1 - import livestock data and rename variables
***********************************************************************

* import livestock info
	use 			"$root/agric/agsec1.dta", clear
	
* order and rename variables
	rename			hh_anm sanml
	rename 			hh_plty pltry
* recode so non-zero is 1
	replace			lvstck = 0 if lvstck == 2
	lab var			lvstck "=1 if household owns livestock"
	
	replace			sanml = 0 if sanml == 2	
	lab var			sanml "=1 if household owns small animals"
	
	replace			sanml = 0 if sanml == 2	
	lab var			pltry "=1 if household owns poultry"
	
	keep 			hhid lvstck sanml pltry
	
	isid			hhid
	order			hhid hh lvstck sanml 
	
	compress

* save file
	save 			"$export/2019_agsec6.dta", replace
	
* close the log
	log	close



/* END */
	


	
