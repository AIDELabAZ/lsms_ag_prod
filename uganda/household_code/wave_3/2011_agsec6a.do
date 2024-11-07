* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 6 Nov 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 3 livestock rosters (2011_AGSEC1)
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
	global root 	"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_3"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_agsec6a_plt", append
	
	
***********************************************************************
**# 1 - import livestock data and rename variables
***********************************************************************

* import livestock info
	use 			"$root/AGSEC1.dta", clear
	
* order and rename variables
	rename			HHID hhid
	format 			%16.0g hhid

	
***********************************************************************
**# 1 - import livestock data and rename variables
***********************************************************************
	
* order and rename variables
	rename 			a6aq1 lvstck
	rename			a6bq1 sanml
	rename 			a6cq1 pltry
	
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
	save 			"$export/2011_agsec6.dta", replace
	
* close the log
	log	close
	


	
