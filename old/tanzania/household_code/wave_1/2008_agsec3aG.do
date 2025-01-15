* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 1 Ag sec3a
	* generates gender variables for decision-makers and 

* assumes
	* access to all raw data
	* distinct.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_1/raw"
	global export 	"$data/household_data/tanzania/wave_1/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log 		close 
	log using 		"$logout/wv1_AGSEC3AG_plt", append


***********************************************************************
**# 1 - prepare TZA 2008 (Wave 1) - Agriculture Section 3A 
***********************************************************************

* load data
	use 		"$root/SEC_3A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped
	
* rename variables
	rename 			s3aq6_1 rosterid
	
	
***********************************************************************
**# 2 - merge with hh roster info- Agriculture Section 3A 
***********************************************************************

* merge with hh roster info 
	merge m:1		hhid rosterid using "$export/AGSEC1A_plt.dta"
	*** unmatched from master: 982
	*** matched 4,1444
	
	drop 			if _merge ==2
	rename 			rosterid mgmt_a
	rename 			gender gender_a
	order 			gender_a, after(mgmt_a)
	drop 			_merge
	
	rename 			s3aq6_2 rosterid
	merge m:1		hhid rosterid using "$export/AGSEC1A_plt"
	*** unmatched from master 3,377
	*** matched 1,749
	
	drop 			if _merge == 2
	rename			rosterid mgmt_b
	rename 			gender gender_b
	order 			gender_b, after(mgmt_b)
	drop 			_merge
	
	rename 			s3aq6_3 rosterid 
	merge m:1 		hhid rosterid using "$export/AGSEC1A_plt"
	*** matched 82
	
	drop 			if _merge == 2
	rename 			rosterid mgmt_c
	rename 			gender gender_c
	order 			gender_c, after(mgmt_c)
	drop			_merge
	
	
	
	
	
* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of the rest
	keep			hhid plotnum plot_id irrigated fert_any kilo_fert ///
						pesticide_any herbicide_any labor_days plotnum ///
						region district ward ea y1_rural clusterid strataid ///
						hhweight
	order			hhid plotnum plot_id
	
* renaming and relabelling variables
	lab var			hhid "Unique Household Identification NPS Y1"
	lab var			y1_rural "Cluster Type"
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			plotnum "Plot ID Within household"
	lab var			plot_id "Unique Plot Identifier"
	lab var			clusterid "Unique Cluster Identification"
	lab var			strataid "Design Strata"
	lab var			region "Region Code"
	lab var			district "District Code"
	lab var			ward "Ward Code"
	lab var			ea "Village / Enumeration Area Code"
	lab var			labor_days "Total Labor (days), Imputed"
	lab var			irrigated "Is plot irrigated?"
	lab var			pesticide_any "Was Pesticide Used?"
	lab var			herbicide_any "Was Herbicide Used?"	
	lab var			kilo_fert "Fertilizer Use (kg), Imputed"
	
		
* prepare for export
	isid			hhid plotnum
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/ag_sec3aG_plt.dta", replace

* close the log
	log	close

/* END */
