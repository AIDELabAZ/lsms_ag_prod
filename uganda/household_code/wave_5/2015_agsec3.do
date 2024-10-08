* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 7 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	* hh roster information from hh questionaire
	* reads Uganda wave 5 hh information (gsec2)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_5/raw"  
	global export 	"$data/household_data/uganda/wave_5/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/hh/gsec2.dta", clear
	
* rename variables			
	rename			h2q1 member_number
	rename 			h2q3 gender

* modify format of pid so it matches pid from other files 
	gen 			PID = substr(pid, 2, 5) + substr(pid, 8, 3)
	destring		PID, replace
	
	isid 			hhid PID

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	keep 			hhid PID member_number gender
	
* save file 
	save 			"$export/2015_gsec2_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
