* Project: LSMS_ag_prod 
* Created on: March 2024
* Created by: alj
* Edited on: 6 November 2024
*** A VERY BAD DAY 
* Edited by: alj 
* Stata v.18.5 

* does
	* cleans crop plot size (gps and self-report)

* assumes
	* access to MWI 6 raw data - PANEL
	
* TO DO:
	* everything 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/raw_lsms_data/malawi/wave_6/raw"	
	loc		export 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/wave_6"
	loc		logout 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_hh_mod_a19", append

* **********************************************************************
* 1 - clean plot area 
* **********************************************************************

* load data
	use 			"`root'/hh_mod_a_filt_19.dta", clear

	
* keep what we need
	keep			y4_hhid y3_hhid HHID case_id ea_id hh_wgt /// 
						panelweight_2019 panelweight_2016 panelweight_2013 region district ta_code  /// 
						reside hhsize  
	
* rename some stuff
	rename 			HHID hhid 
* uganda renames to admin1-4, but i'm not sure why so i am not doing that right now
	rename 			reside sector 
	rename 			hh_wgt wgt_hh
	rename 			panelweight_2013 wgt13
	rename 			panelweight_2016 wgt16
	rename 			panelweight_2019 wgt_pnl 
	rename 			hhsize hh_size 
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************
	
	order 			y4_hhid y3_hhid hhid case_id ea_id ///
						region district ta_code ///
						sector hh_size /// 
						wgt13 wgt16 wgt_hh wgt_pnl
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/hh_mod_a_filt_19.dta", replace

* close the log
	log			close


/* END */