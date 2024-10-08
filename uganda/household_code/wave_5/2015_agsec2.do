* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 7 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	* merges agsec2A with hh roster information 
	* reads Uganda wave 5 hh information (AGSE2A)

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
	log using 		"$logout/2015_agsec2_plt", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import hh roster info
	use 			"$root/agric/AGSEC2A.dta", clear
	

* rename variables and prepare for merging 
	rename 			HHID hhid
	rename			parcelID prcid
	
	isid			hhid a2aq24a
	
***********************************************************************
**# 2 - ,erge with hh information 
***********************************************************************	

	merge 1:m 		hhid prcid using "$export/2015_gsec2_plt.dta"
	
