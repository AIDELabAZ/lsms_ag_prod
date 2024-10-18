* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 15 Oct 24
* Edited by: rg
* Stata v.18, mac

* does
	* household Location data (2010_GSEC1) for the 1st season

* assumes
	* access to all raw data
	* mdesc.ado

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
	log using 			"$logout/2010_GSEC1_plt", append

	
************************************************************************
**# 1 - UNPS 2009 (Wave 2) - General(?) Section 1 
************************************************************************

* import wave 2 season 1
	use 			"$root/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			h1aq1 district
	rename 			h1aq2b county
	rename 			h1aq3b subcounty
	rename 			h1aq4b parish
	rename 			hh_status hh_status2010
	***	district variables not labeled in this wave, just coded

	tab 			region, missing

* drop if missing
	drop if			district == ""
	*** dropped 25 observations
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid region district county subcounty parish ///
						hh_status2010 spitoff09_10 spitoff10_11 wgt10

	compress
	describe
	summarize

* save file
	save 			"$export/2010_GSEC1_plt.dta", replace

* close the log
	log	close

/* END */	
