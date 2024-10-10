* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 8 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	* merges agsec2 with decision-maker info (AGSEC3B)
	* reads Uganda wave 5 (AGSEC3B)

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
	log using 		"$logout/2015_agsec3_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/agric/AGSEC3B.dta", clear
	
* rename variables			
	rename 			HHID hhid 
	rename			parcelID prcid
	rename 			a3bq3_3 PID

***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	
	merge 1:m 		hhid hh prcid using "$export/2015_agsec2_plt.dta"
	* drop 

	
