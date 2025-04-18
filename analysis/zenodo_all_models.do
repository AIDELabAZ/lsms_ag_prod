* Project: LSMS_ag_prod 
* Created on: Jan 2025
* Created by: rg
* Edited on: 18 April 25
* Edited by: rg
* Stata v.18.0

* does
	* adapts our code using ZENODO dataset 
	* uses tight sample
	* drops mali before running models 4 and 5

* assumes
	* access to replication data
	
* notes:

	
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
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear	
	
			
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test)!=float(total_wgt_survey)
	* dropped 0
	
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* generate dummy variables for each country	
	encode 		country, gen(Country)
	
	
***********************************************************************
**# 2 - model 1: plot-level
***********************************************************************
	
* run survey-weighted regression 
	svyset 		ea [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	
	svy: 		reg ln_harvest_value_cp c.year i.Country
	
	local 		lb = _b[year] - invttail(e(df_r), 0.025) * _se[year]
	local 		ub = _b[year] + invttail(e(df_r), 0.025) * _se[year]
	estimates 	store A
	
	
	local 		r2 = e(r2_a)
	di 			"`lb', `ub', `r2'"

	
***********************************************************************
**# 3 - model 2: plot-level
***********************************************************************

	global inputs_cp ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index
	
	global controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp
	
	global 	geo ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation tot_precip_sd_season agro_ecological_zone temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season 

* encode main crop	
	encode 		main_crop, gen(Main_crop)


	label 		define yes_no 0 "No" 1 "Yes"
* destring 
	foreach var in 	miss_harvest_value_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock formal_education_manager female_manager hh_electricity_access urban plot_owned {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
		
	}
	
* generate dummy for crops
	levelsof 	Main_crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (Main_crop == `crop_code') 
	}	
	
* estimate model 2
	svyset, clear
	svyset 		ea [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	
	svy: 		reg ln_harvest_value_cp year country_dummy* indc_* $inputs_cp $controls_cp $geo
	
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	di 			"`lb', `ub',"
	
	estimates 	store B



***********************************************************************
**# 4 - model 3 - farm level
***********************************************************************

* creating missing value indicators at plot level
foreach var in harvest_value    total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   seed_value seed_kg inorganic_fertilizer_value     harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con     {
		replace `var'=`var'*plot_area
}

* we have to identify the main crop of the hh
	bys 	hh_id wave main_crop: egen value_maincrop = total(harvest_value_cp)
	bys 	hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop
	
	
drop miss_*
	foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen mi_`var'=1 if `var'==. 
	}	
	
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop cluster_id /// 
				(max) female_manager formal_education_manager hh_size ea /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_road ln_dist_popcenter ln_elevation ///
				soil_fertility_index country_dummy* indc_* ///
				(sum) harvest_value_cp ln_seed_value_cp /// 
				ln_hired_labor_value_constant ln_inorganic_fert_value_con /// 
				(sum) plot_area /// 
				(max) organic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) tot_precip_sd_season agro_ecological_zone temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season  ///
				(count) mi_* /// 
				(count)n_harvest_value = harvest_value /// 
				n_seed_value = seed_value /// 
				n_seed_kg = seed_kg /// 
				n_inorganic_fertilizer_value = inorganic_fertilizer_value /// 
				n_total_labor_days = total_labor_days /// 
				n_total_family_labor_days = total_family_labor_days /// 
				n_total_hired_labor_days = total_hired_labor_days /// 
				n_hired_labor_value = hired_labor_value n_plot_area=plot_area /// 
				n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp /// 
				n_hired_labor_value_constant = hired_labor_value_constant /// 
				n_inorganic_fert_value_con = inorganic_fert_value_con /// 
				n_labor_days_nonhired = labor_days_nonhired, /// 
				by(hh_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
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
	
			
	svyset, 	clear
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

	
* run model 3
	*erase 		"$export1/tables/model3/yield.tex"
	*erase 		"$export1/tables/model3/yield.txt"
	

	svy: 		reg  ln_harvest_value_cp $selbaseline 

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
				
* keep only observations included in the regression
	*keep if 	e(sample)
	*keep 		wave country survey hh_id
	
* save for merge 
	*save 		"$export1/dta_files_merge/hh_included_zenodo.dta", replace
	
***********************************************************************
**# 5 - model 4 - hh FE 
***********************************************************************

* drop mali 
	drop if 	country == "Mali"
	
	drop 		country_dummy3
	
* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned tot_precip_sd_season tot_precip_min_season /// 
				soil_fertility_index country_dummy* indc_*) vce(bootstrap)

				
* describe survey design 
	svydes 		ln_harvest_value_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea): gen ID = sum(ea != ea[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  country_dummy1 country_dummy2 country_dummy3 country_dummy4 country_dummy5 o.country_dummy6
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(hh_id) // many reps fail due to collinearities in controls

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
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear

* merge hh 
	merge m:1 	country wave hh_id using "$export1/dta_files_merge/hh_included_zenodo.dta"

	keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	drop 		_merge
	
* merge manager 
	merge m:1 	country wave hh_id plot_manager_id /// 
				using "$export1/dta_files_merge/manager_included_zenodo.dta"
	
	keep if 	_merge == 3 | country == "Mali"
	
* generate dummy for crops
	levelsof 	main_crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 	clean_label = subinstr("`crop_code'", "/", "_", .)  
		local 	clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 	indc_`clean_label' = (main_crop == "`crop_code'")
	}

* generate log variables for inputs and controls 
	rename 		plot_are plot_area_GPS
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	rename 		ln_inorganic_fert_value_con ln_fert_value_cp
	rename 		inorganic_fert_value_con fert_value_cp

	label 		define yes_no 0 "No" 1 "Yes"
* destring 
	foreach var in 	used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock formal_education_manager female_manager hh_electricity_access urban plot_owned {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
	}
	
* we have to identify the main crop - plot-manager
	bys 	plot_manager_id wave main_crop: egen value_maincrop = total(harvest_value)
	bys 	plot_manager_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop
	
* creating missing value indicators at plot level
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a plot-manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop cluster_id hh_id /// 
				(max) female_manager formal_education_manager hh_size ea /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index country_dummy* indc_* ///
				(sum) harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) tot_precip_sd_season tot_precip_min_season ///
				(count) mi_* /// 
				(count) n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(plot_manager_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		ln_`var' = asinh(`var')
					lab var ln_`var' "Natural log of `var'"
				}
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	** 0 observations dropped
	
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* drop mali 
	drop if 	country == "Mali"
	
	drop 		country_dummy3
	
* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned tot_precip_sd_season tot_precip_min_season /// 
				country_dummy* indc_*) vce(bootstrap)

				
* describe survey design 
	svydes 		ln_harvest_value_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea): gen ID = sum(ea != ea[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	*global 		remove  country_dummy1 country_dummy2 country_dummy3 country_dummy4 country_dummy5 o.country_dummy6
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"

* estimate model 5
	*erase 		"$export1/tables/model5/yield.tex"
	*erase 		"$export1/tables/model5/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(plot_manager_id) 
	*local lb 	= _b[year] - invttail(e(df_r),0.025)*_se[year]
	*local ub 	= _b[year] + invttail(e(df_r),0.025)*_se[year]
				
	estimates 	store E
	*test 		$test
	*local 		F1 = r(F)
	*outreg2 	using "$export1/tables/model5/yield.tex",  /// 
				keep(c.year  $sel ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append

* keep only observations included in the regression
	*keep if 	e(sample)
	*keep 		wave country survey hh_id plot_manager_id
	
* save for merge 
	*save 		"$export1/dta_files_merge/manager_included_zenodo.dta", replace
	
	
***********************************************************************
**# 7 - model 6 - cluster 
***********************************************************************	


* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
* merge hh 
	merge m:1 	country wave hh_id using "$export1/dta_files_merge/hh_included_zenodo.dta"

	keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	drop 		_merge
	
* merge manager 
	merge m:1 	country wave hh_id plot_manager_id /// 
				using "$export1/dta_files_merge/manager_included_zenodo.dta"
	
	keep if 	_merge == 3 | country == "Mali"

	
* generate dummy for crops
	levelsof 	main_crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 	clean_label = subinstr("`crop_code'", "/", "_", .)  
		local 	clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 	indc_`clean_label' = (main_crop == "`crop_code'")
	}

* generate log variables for inputs and controls 
	rename 		plot_are plot_area_GPS
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	rename 		ln_inorganic_fert_value_con ln_fert_value_cp
	rename 		inorganic_fert_value_con fert_value_cp

	label 		define yes_no 0 "No" 1 "Yes"
* destring 
	foreach var in 	used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock formal_education_manager female_manager hh_electricity_access urban plot_owned {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
	}
		
* we have to identify the main crop of the hh
	bys 	hh_id wave main_crop: egen value_maincrop = total(harvest_value_cp)
	bys 	hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop


* creating missing value indicators at plot level
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop cluster_id /// 
				(max) female_manager formal_education_manager hh_size ea /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index country_dummy* indc_* ///
				(sum) harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) tot_precip_sd_season tot_precip_min_season ///
				(count) mi_* /// 
				(count) n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(hh_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}
						
* we have to identify the main crop by cluster
	bys 	cluster_id wave main_crop: egen value_maincrop = total(harvest_value)
	bys 	cluster_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop

* creating missing value indicators at plot level
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline"

* collapse the data to a plot-manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* main_crop  /// 
				(max) female_manager formal_education_manager hh_size ea /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index country_dummy* indc_* ///
				(sum) harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) tot_precip_sd_season tot_precip_min_season ///
				(count) mi_* /// 
				(count) n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(cluster_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					replace 	`var' = . if n_`var' == 0
					drop 		n_`var'
				}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		miss_`var' = 1 if mi_`var' >= 1 | `var' == .
					replace miss_`var' = 0 if mi_`var' == 0 
					label var miss_`var' "Flag: Does `var' contain one or more missing values at the plot level?"
					lab 	val miss_`var' miss_`var'
					drop 	mi_`var'
				}

				
* generate new variables containing ln of the original variable
	foreach 	var of varlist harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS  {
					gen		ln_`var' = asinh(`var')
					lab var ln_`var' "Natural log of `var'"
				}
				
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	*** dropped 0 
	
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	
	drop 		scalar temp_weight_test
	
				
* survey design
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned tot_precip_sd_season tot_precip_min_season /// 
				country_dummy* indc_*) vce(bootstrap)

				
* describe survey design 
	svydes 		ln_harvest_value_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea): gen ID = sum(ea != ea[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  country_dummy1 country_dummy2 country_dummy3 country_dummy4 country_dummy5 o.country_dummy6
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 6
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(ea) // many reps fail due to collinearities in controls

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
				ylab(0.09 "9" 0.08 "8" 0.07 "7" 0.06 "6" 0.05 "5" /// 
				0.04 "4" 0.03 "3" 0.02 "2" /// 
				0.01 "1" 0 "0" -0.01 "-1" -0.02 "-2" /// 
				-0.03 "-3" -0.04 "-4" -0.05 "-5" -0.06 "-6" , labsize(small) grid) /// 
				ytitle(Annual productivity change (%)) vertical xsize(5)

				
***********************************************************************
**# 9 - country-level results
***********************************************************************
	
* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
* merge hh 
	merge m:1 	country wave hh_id using "$export1/dta_files_merge/hh_included_zenodo.dta"

	keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	drop 		_merge
	
* merge manager 
	merge m:1 	country wave hh_id plot_manager_id /// 
				using "$export1/dta_files_merge/manager_included_zenodo.dta"
	
	keep if 	_merge == 3 | country == "Mali"
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
	erase 		"$export1/tables/country_level/yield_country_zenodo.tex"
	*erase 		"$export1/tables/country_level/yield_country_zenodo.txt"	

	
	eststo clear 
	
*loop by country 
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)	
	
	eststo: svy: 		reg ln_harvest_value_cp c.year if country=="`country'" 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2		using "$export1/tables/country_level/yield_country_zenodo.tex", /// 
				keep(c.year country_dummy*) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, country FE, YES)  append
	}				

	esttab  ///
			using "$export1/tables/country_level/yield_country_zenodo.tex", replace r2 ///
			title("Country level results") ///
			nonumber mtitles("Ethiopia" "Malawi" "Mali" "Niger" "Nigeria" "Tanzania") ///
			keep(year* ) ///
			coeflabel (year "Annual Time Trend") /// 
			star(* 0.10 * 0.05 ** 0.01) /// 
			ci nonumber 

	
***********************************************************************
**#  - save data to get aez for tanzania wave 4 and 5
***********************************************************************

* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear	
	
* keep necessary vars
	keep 		lat_modified lon_modified agro_ecological_zone country 
	
	duplicates 	drop lat_modified lon_modified, force
	
	drop 		if agro_eco == ""
	
	drop		if lat_mod == . | lon_mod == .
	
	isid 		lat_mod lon_mod
	
* save 
	save 		"$data/countries/aggregate/aez_zenodo_merge.dta", replace 	
				
		
