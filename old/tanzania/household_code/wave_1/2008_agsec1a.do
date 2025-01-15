* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: rg
* Edited on: 16 Oct 2024
* Edited by: rg
* Stata v.18, mac

* does
	* gets Tanzania household roster variables (hhid, rosterid, and gender), wave 1 Ag sec1a

* assumes
	* access to all raw data
	* distinct.ado

* TO DO:
	* completed

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_1/raw"
	global export 	"$data/household_data/tanzania/wave_1/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap 			log close 
	log 			using "$logout/AGSEC1A_plt", append


	
************************************************************************
**# 1 - prepare TZA 2008 (Wave 1) - HH Roster
************************************************************************

* load data
	use				"$root/SEC_1_ALL", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* rename variable
	rename 			s1q3 gender 
	
	keep 			hhid rosterid gender
	mdesc 			hhid rosterid 
	* 1 obs missing rosterid and gender 
	
	drop 			if rosterid ==.
	isid			hhid rosterid
	sort 			hhid rosterid
	
************************************************************************
**# 2 - save file
************************************************************************

	compress
	describe
	summarize 
	save 			"$export/AGSEC1A_plt.dta", replace
	
* close the log
	log	close

/* END */
