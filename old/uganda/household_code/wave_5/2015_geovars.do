* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 31 Oct 24
* Edited by: rg
* Stata v.18.0, mac

* does
	* reads Uganda wave 3 geovars (Geovars_1112)
	* this wave (5) is missing geovars
	* cleans and outputs geovars
		* aez
		* urban/rural
		* elevation
		* soil variables for use in index
		* distances to road and pop center

* assumes
	* customsave.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 		"$data/raw_lsms_data/uganda/wave_3/raw"  
	global export 		"$data/lsms_ag_prod_data/refined_data/uganda/wave_5"
	global logout 		"$data/lsms_ag_prod_data/refined_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2015_geovars", append

	
* **********************************************************************
* 1 - UNPS 2011 (wave 1) - geovars 
* **********************************************************************

* import wave 1 geovars
	use 			"$root/UNPS_Geovars_1112.dta", clear
	** we use the past wave geovariables because variables were not provided in 2015 data
	
* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			ssa_aez09 aez
	rename			urban sector
	rename			srtm_uga elevat
	rename 			dist_popcenter dist_pop
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid aez sector elevat sq1-sq7 dist_road dist_pop

	destring		hhid, gen(hhid_pnl)
	format %16.0g 	hhid_pnl
	
	isid			hhid_pnl
	
	compress

* save file
	save			"$export/2015_geovars.dta", replace

* close the log
	log	close

/* END */	
