* Project: WB Weather
* Created on: Oct 2020
* Created by: jdm

* Edited by: jdm
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans geovars

* assumes
	* access to all raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_1/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_1"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2009_geovars_plt", append

	
* **********************************************************************
* 1 - UNPS 2009 (Wave 1) - geovars
* **********************************************************************

* import wave 1 geovars
	use 			"$root/2009_UNPS_Geovars_0910_plt.dta", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			ssa_aez09 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid aez

	compress
	describe
	summarize

* save file
	save 			"$export/2009_geovars_plt.dta", replace

* close the log
	log	close

/* END */	
