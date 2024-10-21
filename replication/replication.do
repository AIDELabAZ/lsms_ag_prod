* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: jdm
* Edited on: 21 Oct 24
* Edited by:jdm
* Stata v.18.5

* does
	* reads in and conducts replication of Wollburg et al.

* assumes
	* access to replication data
	
* TO DO:
	* 
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/replication", append

	
***********************************************************************
**# 1 - import replication data 
***********************************************************************

* import data
	import 			delimited "$root/LSMS_mega_panel_ARCHIVE090822.csv", clear
	
* generate log yield
	gen				ln_yield = asinh(harvest_value_cp/plot_area)

* generate time trend
	sort			year
	egen			tindex = group(year)
	
* estimate model 1
	reg				ln_yield tindex country_dummy1 country_dummy2 country_dummy3 ///
						country_dummy4 country_dummy5 country_dummy6