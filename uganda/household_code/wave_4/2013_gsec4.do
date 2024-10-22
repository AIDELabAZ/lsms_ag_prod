* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 21 Oct 24
* Edited by: jdm
* Stata v.18.5

* does
	* reads Uganda wave 4 hh information (gsec4)
	* cleans education of household member
	* outputs file for merging with plot owner (agsec2a and agsec2b)

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
	log using 		"$logout/2013_gsec4_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec4.dta", clear
	
* rename variables			
	rename			h4q7 education

* modify format of pid so it matches pid from other files 
	rename			PID pid
	gen 			PID = substr(pid, 2, 5) + substr(pid, 8, 3)
	destring		PID, replace
	
	gen 			hhid = substr(HHID, 2, 5) + substr(HHID, 8,2) + substr(HHID, 11, 2)
	destring		hhid, replace
	
	isid 			hhid PID
	order 			hhid, after(education)
	order			education, after(PID)
	
	rename			education edu
	
	replace			edu = 1 if edu != .
	replace			edu = 0 if edu == .
	
	lab var			edu "=1 if has formal education"
	lab values 		edu .
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid PID edu
	
* save file 
	save 			"$export/2013_gsec4.dta", replace	
	
* close the log
	log	close

/* END */
	


	
