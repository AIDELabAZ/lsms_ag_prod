* Project: Rodrigo thesis
* Created on: January 2025
* Created by: rg
* Edited on: 25 March 2025
* Edited by: rg
* Stata v.18.0

* does
	* create descriptive stats table of variables and graph

* assumes
	* clean data all countries and rounds
	
* TO DO:
	* axis titles, legend, colors etc.
	
	* NOTE: try creating graphs using pytho, it might be easier 
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/countries"
	global 	logout 		"$data/logs"
	global 	export1 	"$output/graphs&tables"
	
* open log	
	cap log 		close
	log using 		"$logout/descriptive_stats", append

	
***********************************************************************
**# 1 - data 
***********************************************************************

* load the data 
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear		
	
***********************************************************************
**# 2 - descriptive statistics table 
***********************************************************************
	
* combine country and wave vars
	egen 		country_wave = group(country wave), label
	
* create the table 
	estpost 	tabstat yield_cp plot_area_GPS seed_value_cp /// 
				total_labor_days, by(country_wave) ///
				statistics(mean sd) columns(variables)
				

* do the same using zenodo data
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear 
	
* combine country and wave vars
	egen 		country_wave = group(country wave), label
	
* create the table 
	estpost 	tabstat harvest_value_cp plot_area seed_value_cp /// 
				labor_days_nonhired, by(country_wave) ///
				statistics(mean sd) columns(variables)
					


***********************************************************************
**# 3 - figure - percent of plots by crop category
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

