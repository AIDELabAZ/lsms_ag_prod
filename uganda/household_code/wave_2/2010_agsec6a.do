* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 25 Oct 24
* Edited by: rg
* Stata v.18.0

* does
	* reads Uganda wave 2 livestock rosters (AGSEC6A, 6B, 6C)
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
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_agsec6a_plt", append
	
	
***********************************************************************
**# 1 - import livestock data and rename variables
***********************************************************************

* import livestock info
	use 			"$root/AGSEC6A.dta", clear
	
* order and rename variables
	rename			HHID hhid
	rename			a6aq4 lvstck
	
* recode so non-zero is 1
	replace			lvstck = 0 if lvstck == 2

	keep 			hhid  lvstck
	
	lab var			lvstck "=1 if household owns livestock"
	
	collapse 		(max) lvstck, by(hhid)
	
	isid			hhid
	
	compress
	
* save file 
	save 			"$export/2010_agsec6a.dta", replace	

	
***********************************************************************
**# 2 - import small animal data and rename variables
***********************************************************************

* import small animal info
	use 			"$root/AGSEC6B.dta", clear
	
* order and rename variables
	rename			HHID hhid
	rename			a6bq4 sanml
	
* recode so non-zero is 1
	replace			sanml = 0 if sanml == 2

	keep 			hhid hh sanml
	
	lab var			sanml "=1 if household owns small animals"
	
	collapse 		(max) sanml, by(hhid)
	
	isid			hhid
	
	compress
	
* save file 
	save 			"$export/2010_agsec6b.dta", replace

	
***********************************************************************
**# 3 - import poultry data and rename variables
***********************************************************************

* import poultry info
	use 			"$root/AGSEC6C.dta", clear
	
* order and rename variables
	rename			HHID hhid
	rename			a6cq4 pltry
	
* recode so non-zero is 1
	replace			pltry = 0 if pltry == 2

	keep 			hhid hh pltry
	
	lab var			pltry "=1 if household owns poultry"
	
	collapse 		(max) pltry, by(hhid)
	
	isid			hhid
	
	compress
	
***********************************************************************
**# 4 - merge in other two files
***********************************************************************

* merge in livestock
	merge 1:1		hhid using "$export/2010_agsec6a.dta"
	* 762 not merged from master
	
	drop			if _merge == 2
	drop			_merge

* merge in small animals
	merge 1:1		hhid using "$export/2010_agsec6b.dta"
	* 417 not matched from master
	
	drop			if _merge == 2
	drop			_merge
	
***********************************************************************
**# 5 - end matter, clean up to save
***********************************************************************
		
	erase			"$export/2010_agsec6a.dta"
	erase			"$export/2010_agsec6b.dta"
	
		
	isid			hhid

	order			hhid hh lvstck sanml 
	
	compress

* save file
	save 			"$export/2010_agsec6.dta", replace
	
* close the log
	log	close

/* END */
	


	
