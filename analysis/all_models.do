* Project: LSMS_ag_prod
* Created on: Jan 2025
* Created by: rg
* Edited on: 29 Jan 25
* Edited by: rg
* Stata v.18.0

* does
	* reads in and conducts replication of Wollburg et al.

* assumes
	* access to replication data
	
* TO DO:
	*  the code for all models run, but we need to update them with the final variables 
	* (inputs at constant prices, harvest at constant prices) and generate 
	* a few additional variables (cluster_id, plot_manager_id, ea, etc...)
	
	
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
*	log using 		"$logout", append
	*** i'm not getting this to work, but don't want to bother to fix it
	
***********************************************************************
**# 1 (a) - table 1 country-level baseline results using their code and zenodo mega panel 
***********************************************************************
/*
* we are using the data set LSMS Mega panel
	use  		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
* count observations per country 
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
				count if 	country == "`country'"
	}
	*** more observations than the values reported in table 1.
	
* create necessary vars for replication 
	drop if		pw ==. 
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* replicate country-level results
	erase 		"$export1/tables/country_level/ln_harvest_value_cp.tex"
	erase 		"$export1/tables/country_level/ln_harvest_value_cp.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {

	svyset 		ea [pweight=wgt_adj_surveypop], strata(strataid) singleunit(centered)	
	
	svy: 		reg ln_harvest_value_cp c.year if country=="`country'" 
	local 		lb = _b[c.year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[c.year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 	using "$export1/tables/country_level/ln_harvest_value_cp.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp) ctitle("`country'- model 1") 	/// 
				addstat(  Upper bound CI, `ub', Lower bound CI, `lb') /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
}
*/
***********************************************************************
**# 1 (b) - country-level baseline results 
***********************************************************************

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_year.dta", clear
		
* generate log yield
	gen			ln_yield1 = asinh(yield_kg1)
	gen 		ln_yield2 = asinh(yield_kg2)

* generate time trend
*	sort		year
*	egen		tindex = group(year)
	
*** NOTE DEFAULT FOR SVY IS ROBUST STANDARD ERRORS 	

* estimate country-level for yield 1
	erase 		"$export1/tables/country_level/yield1.tex"
	erase 		"$export1/tables/country_level/yield1.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	foreach		country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset 		ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg 	ln_yield1 c.year if country=="`country'" 
	local 		lb = _b[c.year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[c.year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 	using "$export1/tables/country_level/yield1.tex", keep(c.year) /// 
				ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', /// 
				Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES) append
}

* estimate country-level for yield 2
	erase 		"$export1/tables/country_level/yield2.tex"
	erase 		"$export1/tables/country_level/yield2.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset 		ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg 	ln_yield2 c.year if country=="`country'"
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 	using "$export1/tables/country_level/yield2.tex",   keep(c.year) /// 
				ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', /// 
				Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}


***********************************************************************
**# 2 - model 1: plot-level
***********************************************************************

* create total_wgt_survey varianble (not sure if it's like this)
	drop if		pw ==. 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* encode country variable to generate dummies
	encode		country, gen(Country)
	
* run survey-weighted regression 
	svyset 		ea_id_obs [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	*** they created an ea variable (used instead of ea_id_obs)
	
	svy: 		reg ln_yield1 year i.Country 
	local 		lb = _b[year] - invttail(e(df_r), 0.025) * _se[year]
	local 		ub = _b[year] + invttail(e(df_r), 0.025) * _se[year]
	outreg2		using "$export1/tables/model1/yield.tex", keep(c.year i.Country) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  replace
	local 		r2 = e(r2_a)
	di 			"`lb', `ub', `r2'"
	estimates 	store A
	
***********************************************************************
**# 3 - model 2: plot-level
***********************************************************************

* generate log variables for inputs and controls 
	gen 		ln_total_labor_days1 = asinh(total_labor_days1)
	gen 		ln_seed_kg1 = asinh(seed_kg1)	
	gen			ln_nitrogen_kg1 = asinh(nitrogen_kg1)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	*gen 		ln_elevation = asinh(elevation)

	
* define input and control globals 
	global 		inputs_cp1 ln_total_labor_days1 ln_seed_kg1 ln_nitrogen_kg1  
	global 		controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned 
	*** in this global they used miss_harvest_value_cp
	
	global 		geo  ln_dist_popcenter soil_fertility_index   
	*** included but we do not have it yet: i.agro_ecological_zone, ln_dist_road, ln_elevation
	
	global 		FE c.year i.Country i.crop 
	*** instead of crop they use Main_crop
	
	* check 0b. pre-analysis do file- lines 60 to 70 to see how they defined next global
	
	* global 	$weather_all
	
* lasso linear regression to select variables
	lasso		linear ln_yield1 ($FE c.year $inputs_cp $controls_cp ) $geo $weather_all , nolog rseed(9824) selection(plugin) 
	
	lassocoef
	
	global		selbaseline `e(allvars_sel)'
	*** these are the variables selected by LASSO
	
	global 		testbaseline `e(othervars_sel)'
	*** these are the ones not selected by LASSO
	
* estimate model 2
	erase 		"$export1/tables/model2/yield.tex"
	erase 		"$export1/tables/model2/yield.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	svy: 		reg ln_yield1 1.Country 1.crop $selbaseline 
	*** they use 1.Main_crop here
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	di 			"`lb', `ub',"
	
	estimates 	store B
	test 		$testbaseline
	local 		F1 = r(F) 
	test 		$inputs_cp
	global 		F2 = r(F)
	outreg2 	using "$export1/tables/model2/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls") /// 
				addstat(  Upper bound CI, `ub', Lower bound CI, `lb') /// 
				addtext(Main crop FE, YES, Country FE, YES)  append


***********************************************************************
**# 4 - model 3 - farm level
***********************************************************************

* adjust values plot size 
	foreach 	var of varlist harvest_kg1 total_labor_days1 seed_kg1 nitrogen_kg1{
					replace `var' = `var' * plot_area_GPS
				}
	*** lines 41 and 42 --> baseline results do-file

* we have to identify the main crop of the hh

	* determine total harvest for each crop within hh 
	bysort		 hh_id_obs wave crop: egen harvest_maincrop = total(harvest_kg1)
	
	* identify the main crop 
	bysort		hh_id_obs wave (harvest_maincrop): gen main_crop2 = crop[_N]
	
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* attach labels
	lab 		define main_crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values main_crop main_crop
	lab var		main_crop "Main Crop group of hh"

	* check how many main_crop == .
	tab 		main_crop, missing
	*** 31.23 % missing total
	
	distinct 	hh_id_obs if main_crop == .
	*** 31,468 hh with main_crop missing (28% of hh)


* creating missing value indicators
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen 	mi_`var' = 1 if `var' == .
				}
* to display lasso vars we can do this:
	di "$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter strataid intercropped pw urban ln_dist_popcenter ///
				soil_fertility_index ///
				(sum) harvest_kg1 seed_kg1 nitrogen_kg1 total_labor_days1 /// 
				plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock plot_owned ///
				irrigated /// 
				(mean) age_manager year /// 
				(count) mi_* /// 
				(count) n_harvest_kg1 = harvest_kg1 n_seed_kg1 = seed_kg1 /// 
				n_nitrogen_kg1 = nitrogen_kg1 n_total_labor_days1 = total_labor_days1 ///
				n_plot_area_GPS = plot_area_GPS, by(hh_id_obs wave)
				
		*** check line 57 do-file Baseline results - including variables not in the 
		*** the dataset. (for example: self_reported area.) They already have weather 
		*** variables at this point
		*** keeping ea_id_obs to see if model runs (we need to creare an ea variable)
		
		
* replace invalid observations with missing values and drop flag variables 
	foreach		var of varlist harvest_kg seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}

* flag variables with plots containing one or more missing observations
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

* calculate per-unit area values 
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = `var'/plot_area_GPS
				}
				
* generate new variables containing ln of the original variable +1
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		ln_`var' = ln(`var' + 1)
					lab var ln_`var' "Natural log of `var'"
				}
				
* generate dummy variables for each country	
	encode 		country, gen(Country)
	tab			Country, gen(country_dummy)
	
* generate variables necessary for analysis
	gen 		ln_plot_area = ln(plot_area_GPS)
	** they gen total labor days nonhired 
	** then they take the ln of total labor nonhired
	
* create total_wgt_survey varianble (not sure if it's like this)
	drop if		pw ==. 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels
	lab 		define main_crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values main_crop main_crop
	lab var		main_crop "Main Crop group of hh"
			
* run model 3
	erase 		"$export1/tables/model3/yield.tex"
	erase 		"$export1/tables/model3/yield.txt"
	
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

	svy: 		reg  ln_harvest_kg1 1.Country 1.main_crop $selbaseline
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	estimates 	store C

	*global 		remove   311bn.agro_ecological_zone 314bn.agro_ecological_zone 
	*global 		test : list global(testbaseline) - global(remove)
	*test 		$test
	*local 		F1 = r(F)
	outreg2 	using "$export1/tables/model3/yield.tex",  /// 
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
				bsrweight(ln_harvest_kg1 year ln_plot_area ln_total_labor_days1 /// 
				ln_seed_kg1  ln_nitrogen_kg1  used_pesticides organic_fertilizer irrigated /// 
				intercropped crop_shock hh_shock livestock hh_size formal_education_manager /// 
				female_manager age_manager hh_electricity_access urban plot_owned  /// 
				ln_dist_popcenter soil_fertility_index Country main_crop) vce(bootstrap)
		*** vars included in the original: ln_hired_labor_value_constant, ag_asset_index
		*** miss_harvest_value_cp, ln_dist_road, ln_elevation, tot_precip_sd_season, 
		*** cluster_id, agro_ecological_zone, temperature_min_season, temperature_max_season
		*** temperature_sd_season, temperature_mean_season, temperature_above25C_season
		*** temperature_above30C_season
		
* describe survey design 
	svydes 		ln_harvest_kg1, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 	sel : list global(selbaseline) - global(remove)

* estimate model 4
	erase 		"$export1/tables/model4/yield.tex"
	erase 		"$export1/tables/model4/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_kg1 1.main_crop $sel /// 
				[pw = wgt_adj_surveypop],absorb(hh_id_obs) // many reps fail due to collinearities in controls
	estimates 	store D
	test 		$test
	local 		F1 = r(F)
	outreg2 	using "$export1/tables/model4/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append

***********************************************************************
**# 6 - model 5 - plot-manager
***********************************************************************		

* load data again 
	use 		"$data/countries/aggregate/allrounds_final_year.dta", clear	

* generate log variables for inputs and controls 
	gen 		ln_total_labor_days1 = asinh(total_labor_days1)
	gen 		ln_seed_kg1 = asinh(seed_kg1)	
	gen			ln_nitrogen_kg1 = asinh(nitrogen_kg1)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	*gen 		ln_elevation = asinh(elevation)

* adjust values plot size 
	foreach 	var of varlist harvest_kg1 total_labor_days1 seed_kg1 nitrogen_kg1{
					replace `var' = `var' * plot_area_GPS
				}
				
* we have to identify the main crop of the hh

	* determine total harvest for each crop within hh 
	bysort		 plot_id_obs wave crop: egen harvest_maincrop = total(harvest_kg1)
		*** instead of plot_id_obs is "plot_manager_id"	
	
	* identify the main crop 
	bysort		plot_id_obs wave (harvest_maincrop): gen main_crop2 = crop[_N]
		*** instead of plot_id_obs is "plot_manager_id"
		
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* attach labels
	lab 		define main_crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values main_crop main_crop
	lab var		main_crop "Main Crop group of hh"


* creating missing value indicators
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen 	mi_`var' = 1 if `var' == .
				}

* collapse the data plot-level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter strataid intercropped pw urban ln_dist_popcenter ///
				soil_fertility_index ///
				(sum) harvest_kg1 seed_kg1 nitrogen_kg1 total_labor_days1 /// 
				plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock plot_owned ///
				irrigated /// 
				(mean) age_manager year /// 
				(count) mi_* /// 
				(count) n_harvest_kg1 = harvest_kg1 n_seed_kg1 = seed_kg1 /// 
				n_nitrogen_kg1 = nitrogen_kg1 n_total_labor_days1 = total_labor_days1 ///
				n_plot_area_GPS = plot_area_GPS, by(plot_id_obs wave)
				*** instead of plot_id_obs is "plot_manager_id"
		
* replace invalid observations with missing values and drop flag variables 
	foreach		var of varlist harvest_kg seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}

* flag variables with plots containing one or more missing observations
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

* calculate per-unit area values 
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = `var'/plot_area_GPS
				}
				
* generate new variables containing ln of the original variable +1
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		ln_`var' = ln(`var' + 1)
					lab var ln_`var' "Natural log of `var'"
				}
				
* generate dummy variables for each country	
	encode 		country, gen(Country)
	tab			Country, gen(country_dummy)
	
* generate variables necessary for analysis
	gen 		ln_plot_area = ln(plot_area_GPS)
	** they gen total labor days nonhired 
	** then they take the ln of total labor nonhired
	
* create total_wgt_survey varianble (not sure if it's like this)
	drop if		pw ==. 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels to main crop 
	lab 		define main_crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values main_crop main_crop
	lab var		main_crop "Main Crop group of hh"

* survey design
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_kg1 year ln_plot_area ln_total_labor_days1 /// 
				ln_seed_kg1  ln_nitrogen_kg1  used_pesticides organic_fertilizer irrigated /// 
				intercropped crop_shock hh_shock livestock hh_size formal_education_manager /// 
				female_manager age_manager hh_electricity_access urban plot_owned  /// 
				ln_dist_popcenter soil_fertility_index Country main_crop) vce(bootstrap)
		*** vars included in the original: ln_hired_labor_value_constant, ag_asset_index
		*** miss_harvest_value_cp, ln_dist_road, ln_elevation, tot_precip_sd_season, 
		*** cluster_id, agro_ecological_zone, temperature_min_season, temperature_max_season
		*** temperature_sd_season, temperature_mean_season, temperature_above25C_season
		*** temperature_above30C_season

* describe survey design 
	svydes 		ln_harvest_kg1, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 	sel : list global(selbaseline) - global(remove)

* estimate model 5
	*erase 		"$export1/tables/model5/yield.tex"
	*erase 		"$export1/tables/model5/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_kg1 1.main_crop $sel /// 
				[pw = wgt_adj_surveypop],absorb(plot_id_obs) 
				*** instead of plot_id_obs is "plot_manager_id"
				
	estimates 	store E
	test 		$test
	local 		F1 = r(F)
	outreg2 	using "$export1/tables/model5/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append

***********************************************************************
**# 7 - model 6 - cluster 
***********************************************************************	

* load data again 
	use 		"$data/countries/aggregate/allrounds_final_year.dta", clear	
	
* generate log variables for inputs and controls 
	gen 		ln_total_labor_days1 = asinh(total_labor_days1)
	gen 		ln_seed_kg1 = asinh(seed_kg1)	
	gen			ln_nitrogen_kg1 = asinh(nitrogen_kg1)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	*gen 		ln_elevation = asinh(elevation)
	
* adjust values plot size 
	foreach 	var of varlist harvest_kg1 total_labor_days1 seed_kg1 nitrogen_kg1{
					replace `var' = `var' * plot_area_GPS
				}

* we have to identify the main crop of the hh

	* determine total harvest for each crop within hh 
	bysort		 hh_id_obs wave crop: egen harvest_maincrop = total(harvest_kg1)
	* identify the main crop 
	bysort		hh_id_obs wave (harvest_maincrop): gen main_crop2 = crop[_N]
	* rename variable 	
	drop 		main_crop
	rename 		main_crop2 main_crop
	
	* attach labels
	lab 		define main_crop 1 "Barley" 2 "Beans/Peas/Lentils/Peanuts" 3 "Maize" ///
				4 "Millet" 5 "Nuts/Seeds" 6 "Other" 7 "Rice" ///
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat", replace
	lab 		values main_crop main_crop
	lab var		main_crop "Main Crop group of hh"

* creating missing value indicators
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen 	mi_`var' = 1 if `var' == .
				}

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter strataid intercropped pw urban ln_dist_popcenter ///
				soil_fertility_index ///
				(sum) harvest_kg1 seed_kg1 nitrogen_kg1 total_labor_days1 /// 
				plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock plot_owned ///
				irrigated /// 
				(mean) age_manager year /// 
				(count) mi_* /// 
				(count) n_harvest_kg1 = harvest_kg1 n_seed_kg1 = seed_kg1 /// 
				n_nitrogen_kg1 = nitrogen_kg1 n_total_labor_days1 = total_labor_days1 ///
				n_plot_area_GPS = plot_area_GPS, by(hh_id_obs wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach		var of varlist harvest_kg seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}

* flag variables with plots containing one or more missing observations
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

* generate a new "main crop" variable 
	bysort		cluster_id wave crop: egen harvest_maincrop = total(harvest_kg1)
	bysort		cluster_id wave (harvest_maincrop): gen main_crop2 = crop[_N]
	drop 		main_crop
	rename 		main_crop2 main_crop

* counting missing values
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen 	mi_`var' = 1 if `var' == .
				}

	drop if 	cluster_id==. 

* collapse the data cluster_id
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter strataid intercropped pw urban ln_dist_popcenter ///
				soil_fertility_index ///
				(sum) harvest_kg1 seed_kg1 nitrogen_kg1 total_labor_days1 /// 
				plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock plot_owned ///
				irrigated /// 
				(mean) age_manager year /// 
				(count) mi_* /// 
				(count) n_harvest_kg1 = harvest_kg1 n_seed_kg1 = seed_kg1 /// 
				n_nitrogen_kg1 = nitrogen_kg1 n_total_labor_days1 = total_labor_days1 ///
				n_plot_area_GPS = plot_area_GPS, by(cluster_id wave)
				
* replace invalid observations with missing values and drop flag variables 
	foreach		var of varlist harvest_kg seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
				
* flag variables with plots containing one or more missing observations within clusters
	foreach		var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

* scale for effective input/output
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					replace 	`var' = `var'/plot_area_GPS
				}
				
* generate new variables containing ln of the original variable +1
	foreach 	var of varlist harvest_kg1 seed_kg1 total_labor_days1 /// 
				plot_area_GPS nitrogen_kg1 {
					gen		ln_`var' = ln(`var' + 1)
					lab var ln_`var' "Natural log of `var'"
				}
				
* generate variables for analysis 
	encode 		country, gen(Country)
	tab			Country, gen(country_dummy)
	
* generate variables necessary for analysis
	gen 		ln_plot_area = ln(plot_area_GPS)
	** they gen total labor days nonhired 
	** then they take the ln of total labor nonhired
	
* create total_wgt_survey varianble (not sure if it's like this)
	drop if		pw ==. 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
				
* survey settings		
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_kg1 year ln_plot_area ln_total_labor_days1 /// 
				ln_seed_kg1  ln_nitrogen_kg1  used_pesticides organic_fertilizer irrigated /// 
				intercropped crop_shock hh_shock livestock hh_size formal_education_manager /// 
				female_manager age_manager hh_electricity_access urban plot_owned  /// 
				ln_dist_popcenter soil_fertility_index Country main_crop) vce(bootstrap)
				
* describe survey design 
	svydes 		ln_harvest_kg1, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 	sel : list global(selbaseline) - global(remove)

* estimate model 6
	*erase 		"$export1/tables/model6/yield.tex"
	*erase 		"$export1/tables/model6/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_kg1 1.main_crop $sel /// 
				[pw = wgt_adj_surveypop],absorb(cluster_id) 
				
	estimates 	store F
	test 		$test
	local 		F1 = r(F)
	outreg2 	using "$export1/tables/model6/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append			
				
* END *