* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 2 geovars (UNPS_Geovars_1011)
	* cleans and outputs geovars
		* aez
		* urban/rural
		* elevation
		* soil variables for use in index
		* distances to road and pop center

* assumes
	* access to all raw data

* TO DO:
	* done

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 	"$data/raw_lsms_data/uganda/wave_2/raw"  
	global export 	"$data/lsms_ag_prod_data/refined_data/uganda/wave_2"
	global logout 	"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
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
	rename 			urban sector 
	rename			srtm_uga elevat
	rename 			dist_popcenter dist_pop	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid aez sector elevat sq1-sq7 dist_road dist_pop

	compress
	describe
	summarize

* save file
	save 			"$export/2010_geovars.dta", replace
	
* close the log
	log	close

/* END */	
