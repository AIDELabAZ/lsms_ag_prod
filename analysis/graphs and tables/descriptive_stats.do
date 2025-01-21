* Project: Rodrigo thesis
* Created on: January 2025
* Created by: rg
* Edited on: 20 January 2025
* Edited by: rg
* Stata v.18.0

* does
	* create descriptive stats table of variables and graph

* assumes
	* clean data all countries and rounds
	
* TO DO:
	* create a folder to export results. 
	* suggestion in the path export
		* aggregate/descriptive_stats
	* axis titles, legend, colors etc.
	
	* NOTE: try creating graphs using pytho, it might be easier 
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/countries"
	global 	logout 		"$data/logs"
	*global export 		"$data/lsms_ag_prod_data/refined_data/aggregate/descriptive_stats"
	
* open log	
	cap log 		close
	log using 		"$logout/descriptive_stats", append

	
***********************************************************************
**# 1 - data 
***********************************************************************

* load the data 
	use 		"$root/aggregate/allrounds_final", clear		
	
***********************************************************************
**# 2 - descriptive statistics table 
***********************************************************************
	
* create the table 
	tabstat		urban harvest_kg seed_kg improved used_pesticides crop_shock /// 
				pests_shock rain_shock drought_shock flood_shock yield_kg /// 
				total_labor_days nitrogen_kg organic_fertilizer intercropped /// 
				plot_owned age_manager female_manager formal_education_manager /// 
				irrigated hh_shock hh_size hh_electricity_access harv_missing /// 
				used_seed used_fert plot_tot plot_area_GPS, by(country) ///
				statistics(mean sd)columns(variables)
				
				
* post tabstat results
	estpost 	tabstat urban harvest_kg seed_kg improved used_pesticides crop_shock /// 
				pests_shock rain_shock drought_shock flood_shock yield_kg /// 
				total_labor_days nitrogen_kg organic_fertilizer intercropped /// 
				plot_owned age_manager female_manager formal_education_manager /// 
				irrigated hh_shock hh_size hh_electricity_access harv_missing /// 
				used_seed used_fert plot_tot plot_area_GPS, by(country) statistics(mean sd)


* save output and then transpose 
	*esttab 		using "$export/tabstat_results.dta", replace 
	
* load results 
	use 		"export/tabstat_results.dta", clear
	
* reshape to long format 
	reshape		long mean sd, i(variable) j(country)
	reshape 	wide mean sd, i(variable) j(country)
	
* label variables 
	rename 		mean* *_mean 
	rename 		sd* *_sd 
	
* save or export 


***********************************************************************
**# 3 - figure - percet of plots by crop category
***********************************************************************

* load the data 
	use 		"$root/aggregate/allrounds_final", clear
	
* drop missing 
	drop if 	crop == .
	* 35% is missing 
	
* count plots by country and plot 
	gen 		count_plots = 1
	collapse 	(sum) count_plots, by(country crop)

* generate variable with total plots 
	gen 		total_plots = .
	
* sum plots
	bysort 		country (crop): replace total_plots = sum(count_plots)
	bysort		country: replace total_plots = total_plots[_N]

	
* calculate percentage by crop 
	gen 		percent_crop = (count_plots/total_plots) * 100
	
* create graph 
	graph 	hbar (mean) percent_crop, over(crop, label(angle(45))) ///
			over(country, label(angle(0))) ///
			stack asyvars ///
			legend(label(1 "Barley") label(2 "Beans/Peas/Lentils/Peanuts") ///
				label(3 "Maize") label(4 "Millet") label(5 "Rice") ///
				label(6 "Nuts") label(7 "Sorghum") ///
				label(8 "Tubers/Root Crops") label(9 "Other")) ///
			bar(1, color(blue)) bar(2, color(red)) bar(3, color(green)) ///
			bar(4, color(yellow)) bar(5, color(orange)) ///
			blabel(bar, format(%9.1f))

* save graph 
	*** 

