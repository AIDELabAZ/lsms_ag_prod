* Project: LSMS_ag_prod 
* Created on: Jan 2025
* Created by: rg
* Edited on: 8 March 25
* Edited by: rg
* Stata v.18.0

* does
	* reads in and conducts replication of Wollburg et al.

* assumes
	* access to replication data
	
* notes:
	* run time is on the scale of hours?
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	global export1 	"$output/graphs&tables"
	
* open log	
	cap log 		close
	
	
***********************************************************************
**# 1 - generate  hh_id, plot_manager_id, and cluster_id, main crop
**********************************************************************

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 83,753 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a
	* 53 changes
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country wave hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
* create total_wgt_survey varianble 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
	
***********************************************************************
**# 2 - model 1: plot-level
***********************************************************************

* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)

	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
* run survey-weighted regression 
	svyset 		ea_id_obs [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	
	svy: 		reg ln_yield_cp c.year d_* 
	
	local 		lb = _b[year] - invttail(e(df_r), 0.025) * _se[year]
	local 		ub = _b[year] + invttail(e(df_r), 0.025) * _se[year]
	estimates 	store A
	
	*outreg2		using "$export1/tables/model1/yield.tex", keep(c.year i.Country) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  replace
				
	local 		r2 = e(r2_a)
	di 			"`lb', `ub', `r2'"

	
***********************************************************************
**# 3 - model 2: plot-level
***********************************************************************

* generate log variables for inputs and controls 
	gen 		ln_total_labor_days = asinh(total_labor_days)
	gen 		ln_seed_value_cp = asinh(seed_value_cp)	
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	gen			ln_fert_value_cp = asinh(fert_value_cp)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	*gen 		ln_elevation = asinh(elevation)

	
* define input and control globals 
	global 		inputs_cp ln_total_labor_days ln_seed_value_cp  ln_fert_value_cp ln_plot_area_GPS
	global 		controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned 
	*** in this global they used miss_harvest_value_cp
	
	global 		geo  ln_dist_popcenter soil_fertility_index   
	*** included but we do not have it yet: i.agro_ecological_zone, ln_dist_road, ln_elevation
	
	*global 		FE i.Country i.crop 
	*** instead of crop they use Main_crop
	
	* check 0b. pre-analysis do file- lines 60 to 70 to see how they defined next global
	
	global 		weather_all v01_rf1 v02_rf1 v03_rf1 v04_rf1 v05_rf1 v06_rf1 v07_rf1 v08_rf1 v09_rf1 v10_rf1 v11_rf1 v12_rf1 v13_rf1 v14_rf1
	*** mali only country with missing values (38,564 observations)
	
/*
	* Mali weather data is in v**_1_arc and v**_2_arc , trying to replace the missing values with real values 
	foreach 	i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 {
					replace v`i'_rf1 = v`i'_rf1_t1 if country == "Mali" & v`i'_rf1_t1 !=.
					replace v`i'_rf1 = v`i'_2_t1 if country == "Mali" & v`i'_2_arc !=.
	}
*/
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 	crop_label : label crop `crop_code'
		local 	clean_label = subinstr("`crop_label'", "/", "_", .)  
    
		gen 	indc_`clean_label' = (crop == `crop_code') 
}


* lasso linear regression to select variables
	lasso		linear ln_yield_cp (d_* indc_* c.year $inputs_cp $controls_cp ) $geo $weather_all , nolog rseed(9912) selection(plugin) 
	*** variables in parentheses are always included
	*** vars out of parentheses are subject to selection by LASSO
	lassocoef
	
	global		selbaseline `e(allvars_sel)'
	*** these are all the variables
	
	global 		testbaseline `e(othervars_sel)'
	*** these are the variables chosen that were subject to selection by LASSO
	
* estimate model 2
	*erase 		"$export1/tables/model2/yield.tex"
	*erase 		"$export1/tables/model2/yield.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	svy: 		reg ln_yield_cp $selbaseline 
	
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	di 			"`lb', `ub',"
	
	estimates 	store B
*	test 		$testbaseline
*	local 		F1 = r(F) 
*	test 		$inputs_cp
*	global 		F2 = r(F)
*	outreg2 	using "$export1/tables/model2/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls") /// 
				addstat(  Upper bound CI, `ub', Lower bound CI, `lb') /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
*/


***********************************************************************
**# 4 - model 3 - farm level
***********************************************************************

* we have to identify the main crop of the hh

	* determine value of total harvest for each crop within hh 
	bysort		 hh_id wave crop: egen value_maincrop = total(harvest_value_cp)
	
	* identify the main crop 
	bysort		hh_id wave (value_maincrop): gen main_crop2 = crop[_N]
	
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* drop plot-level crop variable and rename the other one
	drop 		crop
	rename 		main_crop crop
	*** we do this because the selbaseline global dummies are called i.crop, if we leave 
	*** the name as main_crop, we won't be able to run model 3
	
	* attach labels
	lab 		define crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"


* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id hh_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(hh_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		ln_`var' = asinh(`var')
					lab var ln_`var' "Natural log of `var'"
				}
					
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"
			
	svyset, 	clear
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

	
* run model 3
	*erase 		"$export1/tables/model3/yield.tex"
	*erase 		"$export1/tables/model3/yield.txt"
	

	svy: 		reg  ln_yield_cp $selbaseline 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	estimates 	store C

	*global 		remove   311bn.agro_ecological_zone 314bn.agro_ecological_zone 
	*global 		test : list global(testbaseline) - global(remove)
	*test 		$test
	*local 		F1 = r(F)
	*outreg2 	using "$export1/tables/model3/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls") /// 
				addstat(  Upper bound CI, `ub', Lower bound CI, `lb') /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
				
				
***********************************************************************
**# 5 - model 4 - hh FE 
***********************************************************************

* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock livestock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)

				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(4500) seed(123)

	global 		remove  d_Ethiopia d_Mali d_Malawi d_Niger d_Nigeria o.d_Tanzania
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(hh_id_obs) // many reps fail due to collinearities in controls

	estimates 	store D
*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model4/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append



***********************************************************************
**# 6 - model 5 - plot-manager
***********************************************************************		

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 83,753 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a	
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country wave hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 	crop_label : label crop `crop_code'
		local 	clean_label = subinstr("`crop_label'", "/", "_", .)  
    
		gen 	indc_`clean_label' = (crop == `crop_code') 
}	
	
* create total_wgt_survey varianble 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create main crop 
	
	* we have to identify the main crop of the hh

	* determine value of total harvest for each crop within hh 
	bysort		 plot_manager_id wave crop: egen value_maincrop = total(harvest_value_cp)
	
	* identify the main crop 
	bysort		plot_manager_id wave (value_maincrop): gen main_crop2 = crop[_N]
	
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* drop plot-level crop variable and rename the other one
	drop 		crop
	rename 		main_crop crop
		
	* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group - plot manager"
	

* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a plot manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id manager_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(plot_manager_id)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		ln_`var' = asinh(`var')
					lab var ln_`var' "Natural log of `var'"
				}
			
* generate dummy variables for each country	
	encode 		country, gen(Country)
	tab			Country, gen(country_dummy)
		
	
* attach labels to main crop 
	lab 		values crop crop
	lab var		crop "Main Crop group - plot manager"
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* survey design
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock livestock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)


* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(4500) seed(123)

	*global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)

* estimate model 5
	*erase 		"$export1/tables/model5/yield.tex"
	*erase 		"$export1/tables/model5/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(manager_id_obs) 
	*local lb 	= _b[year] - invttail(e(df_r),0.025)*_se[year]
	*local ub 	= _b[year] + invttail(e(df_r),0.025)*_se[year]
				
	estimates 	store E
	*test 		$test
	*local 		F1 = r(F)
	*outreg2 	using "$export1/tables/model5/yield.tex",  /// 
				keep(c.year  $sel ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append


***********************************************************************
**# 7 - model 6 - cluster 
***********************************************************************	

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 83,753 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a	
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country wave hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 	crop_label : label crop `crop_code'
		local 	clean_label = subinstr("`crop_label'", "/", "_", .)  
    
		gen 	indc_`clean_label' = (crop == `crop_code') 
	}	
	
* create total_wgt_survey varianble 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	

* we have to identify the main crop of the hh

	* determine value of total harvest for each crop within hh 
	bysort		 hh_id wave crop: egen value_maincrop = total(harvest_value_cp)
	
	* identify the main crop 
	bysort		hh_id wave (value_maincrop): gen main_crop2 = crop[_N]
	
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* drop plot-level crop variable and rename the other one
	drop 		crop
	rename 		main_crop crop
	*** we do this because the selbaseline global dummies are called i.crop, if we leave 
	*** the name as main_crop, we won't be able to run the model 
	
	* attach labels
	lab 		define crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"


* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id hh_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(hh_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}


* we have to identify the main crop by cluster

	* determine value of total harvest for each crop within hh 
	bysort		 cluster_id wave crop: egen value_maincrop = total(harvest_value_cp)
	
	* identify the main crop 
	bysort		cluster_id wave (value_maincrop): gen main_crop = crop[_N]
	
	
	* rename name so it matches the one in the global $sel
	drop 		crop
	rename 		main_crop crop
	*** we do this because the selbaseline global dummies are called i.crop, if we leave 
	*** the name as main_crop, we won't be able to run the model (because of global)
	
	* attach labels
	lab 		define crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values crop crop
	lab var		crop "Main Crop group - cluster"

* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a plot manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop   /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(cluster_id)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		ln_`var' = asinh(`var')
					lab var ln_`var' "Natural log of `var'"
				}
				
* generate dummy variables for each country	
	encode 		country, gen(Country)
	tab			Country, gen(country_dummy)
	
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group - cluster"
				
* survey design
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock livestock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)
				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(4500) seed(123)

	*global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(ea_id_obs) // many reps fail due to collinearities in controls

	estimates 	store F
*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model6/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
		
				
***********************************************************************
**# 8 - coefficient plot
***********************************************************************		

* create the graph
	set			scheme s1color
	
	coefplot 	(A, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 1) ||  /// 
				(B, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 2) ||  /// 
				(C, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 3) ||  /// 
				(D, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 4) || /// 
				(E, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 5) || ///
				(F, mcolor(navy) ciopts(color(navy) recast(rcap))), bylabel(Model 6) /// 
				byopts(row(1)) keep(year) /// 
				xlabel(none) /// 
				yline(0, lcolor(black%50)) /// 
				ylab(0.10 "10" 0.09 "9" 0.08 "8" 0.07 "7" 0.06 "6" 0.05 "5" 0.04 "4" 0.03 "3" 0.02 "2" /// 
				0.01 "1" 0 "0" -0.01 "-1" -0.02 "-2" -0.03 "-3" -0.04 "-4", labsize(small) grid) /// 
				ytitle(Annual productivity change (%)) vertical xsize(5)
				




			
