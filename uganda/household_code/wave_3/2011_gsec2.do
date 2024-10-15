* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 14 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* hh roster information from hh questionaire
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
	global root 	"$data/household_data/uganda/wave_3/raw"  
	global export 	"$data/household_data/uganda/wave_3/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2011_gsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/GSEC2.dta", clear
	
* rename variables			
	rename 			h2q3 gender
	rename 			HHID hhid

* destring PID and hhid 
	destring		PID, replace
	format 			PID %16.0g
	
	destring		hhid, replace
	format 			hhid %16.0g
	
	*isid 			hhid PID 
	*** hhid and PID do not uniquely idenfify the observations
	
	duplicates 		report hhid PID 
	duplicates		drop hhid PID, force
	*** 72 obsevations dropped
	
	isid 			hhid PID

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************
	keep 			hhid PID gender
	
* save file 
	save 			"$export/2011_gsec2_plt.dta", replace	
	
* close the log
	log	close

/* END */
	


	
