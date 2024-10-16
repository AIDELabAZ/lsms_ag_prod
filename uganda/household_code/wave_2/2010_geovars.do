* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* cleans geovars

* assumes
	* access to all raw data

* TO DO:
	* done

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 		"$data/household_data/uganda/wave_2/raw"  
	global export 		"$data/household_data/uganda/wave_2/refined"
	global logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2010_geovars_plt", append

	
************************************************************************
**# 1 - UNPS 2010 (wave 1) - geovars 
************************************************************************

* import wave 1 geovars
	use 			"$root/UNPS_Geovars_1011.dta", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			ssa_aez09 aez
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid aez

	compress
	describe
	summarize

* save file
	save 			"$export/2010_geovars_plt.dta", replace
	
* close the log
	log	close

/* END */	
