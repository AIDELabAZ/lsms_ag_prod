* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 19 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* hh roster information from hh questionaire (rural/urban)
	* reads Uganda wave 4 hh information (gsec2)

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
	log using 		"$logout/2013_gsec1_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec1.dta", clear

* modify format of hhid so it matches hhid from other files 

	gen 			hhid = substr(HHID, 2, 5) + substr(HHID, 8,2) + substr(HHID, 11, 2)
	destring		hhid, replace
	
	isid 			hhid 
	
	keep 			hhid urban 
	order 			urban, after(hhid)
	
* create dummy for rural/urban
	gen				urban_status =1 if urban ==1 
	replace 		urban_status = 0 if urban_status==.
	
***********************************************************************
**# 2 - merge data (hh roster info)
***********************************************************************
	
	merge 1:m 		hhid using "$export/2013_gsec2_plt.dta"
	** all observations matches 
	
	drop 			_merge
	order 			PID, after(hhid)
	order			gender, after(PID)
	order 			age, after(gender)
	
	
	
***********************************************************************
**# 3 - end matter, clean up to save
***********************************************************************
	
* save file 
	save 			"$export/2013_gsec1_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
