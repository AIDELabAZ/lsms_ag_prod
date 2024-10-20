* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 19 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* electricity information from hh questionaire 
	* reads Uganda wave 4 hh information (gsec10)

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
	log using 		"$logout/2013_gsec10_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec10_1.dta", clear
	
* rename variables			
	rename			h10q1 electricity

* modify format of hhid so it matches pid from other files 
	gen 			hhid = substr(HHID, 2, 5) + substr(HHID, 8,2) + substr(HHID, 11, 2)
	destring		hhid, replace
	
	format 			hhid %16.0g
	isid 			hhid 
	
* generate indicator variable for electricity
	gen 			elec_indc = 1 if electricity == 1
	replace			elec_indc = 0 if elec_indc ==.
	

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	keep 			hhid elec_indc
	
* save file 
	save 			"$export/2013_gsec10_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
