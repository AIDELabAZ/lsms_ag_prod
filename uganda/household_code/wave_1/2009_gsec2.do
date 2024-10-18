* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 17 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* hh roster information from hh questionaire
	* reads Uganda wave 1 hh information (gsec2)

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_1/raw"  
	global export 	"$data/household_data/uganda/wave_1/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/2009_gsec2.dta", clear
	
* rename variables			
	rename			h2q1 member_number
	rename 			h2q3 gender
	rename 			HHID hhid 

	
	isid 			hhid member_number

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	keep 			hhid PID gender member_number
	
* save file 
	save 			"$export/2009_gsec2_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
