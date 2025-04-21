* Project: LSMS_ag_prod 
* Created on: Jan 2025
* Created by: rg
* Edited on: 21 April 25
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

* alj notes
* removing aez and livestock 

	global inputs_cp ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index
	
	global controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp livestock
	
	global 	geo  ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation tot_precip_sd_season temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season 

* encode main crop	
	encode 		main_crop, gen(Main_crop)


	label 		define yes_no 0 "No" 1 "Yes"
* destring 
	foreach		 var in miss_harvest_value_cp livestock used_pesticides /// 
				organic_fertilizer irrigated intercropped inorganic_fertilizer  /// 
				crop_shock hh_shock formal_education_manager female_manager /// 
				hh_electricity_access urban plot_owned self_reported_area {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
		
	}
	
* encode aez 
	encode 		agro_ecological_zone, gen(aez)
	
* generate dummy for aez

	levelsof 	aez, local(aez_levels)

	foreach 	aez_code in `aez_levels' {
    

		local 		aez_label : label (aez) `aez_code'
    
		local 		clean_label = lower("`aez_label'")
		local 		clean_label = subinstr("`clean_label'", "/", "_", .)
		local 		clean_label = subinstr("`clean_label'", "-", "_", .)
		local 		clean_label = subinstr("`clean_label'", " ", "_", .)
		local 		clean_label = subinstr("`clean_label'", "(", "", .)
		local 		clean_label = subinstr("`clean_label'", ")", "", .)
		local 		clean_label = subinstr("`clean_label'", ",", "", .)
		local 		clean_label = subinstr("`clean_label'", ".", "", .)


		if 			inrange(substr("`clean_label'", 1, 1), "0", "9") {
        local 		clean_label = "aez_`clean_label'"
			
			}

		gen 		dzone_`clean_label' = (aez == `aez_code')

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
	
	svy: 		reg ln_harvest_value_cp year country_dummy* indc_* dzone_* $inputs_cp $controls_cp $geo
	
	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	di 			"`lb', `ub',"
	
	estimates 	store B



***********************************************************************
**# 4 - model 3 - farm level
***********************************************************************

* creating missing value indicators at plot level
	foreach 	var in harvest_value total_labor_days total_family_labor_days  /// 
				total_hired_labor_days hired_labor_value seed_value seed_kg  /// 
				inorganic_fertilizer_value harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con     {
			replace 	`var'=`var'*plot_area
}

* we have to identify the main crop of the hh
	bys 	hh_id wave Main_crop: egen value_maincrop = total(harvest_value_cp)
	bys 	hh_id wave (value_maincrop): gen main_crop2 = Main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop
	
	label 	values main_crop Main_crop 
	
	drop 	miss_*
	
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg  total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value  plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 	mi_`var'=1 if `var'==. 
	}	
	
* to display lasso vars we can do this:
	display 	"$selbaseline"
	
	
	collapse 	(first)  country Country country_dummy* year  /// 
				survey month_startseason_calendar month_endseason_calendar /// 
				admin_1* admin_2* admin_3* admin_4* cluster_id main_crop   /// 
				(max) aez dzone_* urban female_manager formal_education_manager /// 
				hh_size  hh_electricity_access  livestock  hh_shock ag_asset_index   /// 
				total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market  /// 
				ln_dist_popcenter ln_dist_road ln_elevation ///
				(max)  soil_fertility_index   ///
				(sum) harvest_value    harvest_transport_cost    /// 
				(sum) harvest_value_cp seed_value_cp hired_labor_value_constant  /// 
				inorganic_fert_value_con    ///
				(max) strataid intercropped     ///
				(sum) total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value labor_days_nonhired ///
				(sum) plot_area  ///
				(sum) seed_value seed_kg  ///
				(sum) inorganic_fertilizer_value    ///
				(max) inorganic_fertilizer organic_fertilizer  ///
				(max)  used_pesticides indc_* ///
				(max) crop_shock   ///
				(max) plot_owned  irrigated     self_reported_area  ///
				(mean) age_manager    ///
				(first) tot_precip_sd_season temperature_sd_season temperature_min_season  /// 
				temperature_max_season temperature_mean_season  ///
				(count) mi_* /// 
				(count) n_harvest_value = harvest_value n_seed_value=seed_value /// 
				n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost  /// 
				n_inorganic_fertilizer_value=inorganic_fertilizer_value   /// 
				n_total_labor_days=total_labor_days /// 
				n_total_family_labor_days=total_family_labor_days /// 
				n_total_hired_labor_days=total_hired_labor_days /// 
				n_hired_labor_value=hired_labor_value n_plot_area=plot_area /// 
				n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp  /// 
				n_hired_labor_value_constant = hired_labor_value_constant /// 
				n_inorganic_fert_value_con = inorganic_fert_value_con , by(hh_id wave)
						
		
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con  {
			replace 	`var'=. if n_`var'==0
			drop 		n_`var'
	} 
	
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value  /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 		miss_`var'=1 if mi_`var'>=1 | `var'==.
			replace	 	miss_`var'=0 if mi_`var'==0 
			lab var 	miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
			lab val 	miss_`var' miss_`var'
			drop 		mi_`var'
	}
	

	foreach 	var in harvest_value seed_value seed_kg inorganic_fertilizer_value /// 
				total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			replace 	`var'=`var'/plot_area
		} 
	 	
	
	foreach 	var in harvest_value seed_value seed_kg inorganic_fertilizer_value /// 
				total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value harvest_value_cp seed_value_cp plot_area /// 
				labor_days_nonhired hired_labor_value_constant inorganic_fert_value_con    {
			gen 		ln_`var'=ln(`var' +1)
			lab var 	ln_`var' "Natural log of `var'"
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
	svy: 		reg  ln_harvest_value_cp year country_dummy* indc_* /// 
				dzone_* $inputs_cp $controls_cp $geo 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	estimates 	store C
				
	
***********************************************************************
**# 5 - model 4 - hh FE 
***********************************************************************

* drop mali 
	drop if 	country == "Mali"
	
	drop 		country_dummy3
	
* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area  /// 
				ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp  /// 
				ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index  /// 
				used_pesticides organic_fertilizer irrigated intercropped crop_shock /// 
				hh_shock livestock hh_size formal_education_manager female_manager /// 
				age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp  /// 
				ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation /// 
				tot_precip_sd_season cluster_id  Country main_crop aez  /// 
				tot_precip_sd_season temperature_sd_season temperature_min_season /// 
				temperature_max_season temperature_mean_season) vce(bootstrap)

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
	
	
* estimate model 4	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp year indc_* dzone_* /// 
				$inputs_cp $controls_cp $geo  /// 
				[pw = wgt_adj_surveypop],absorb(hh_id) // many reps fail due to collinearities in controls

	estimates 	store D

	
***********************************************************************
**# 6 - model 5 - plot-manager
***********************************************************************		

* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
* encode main crop	
	encode 		main_crop, gen(Main_crop)
	
* generate dummy variables for each country	
	encode 		country, gen(Country)


	label 		define yes_no 0 "No" 1 "Yes"
	
* destring 
	foreach 	var in 	miss_harvest_value_cp livestock used_pesticides /// 
				organic_fertilizer irrigated intercropped inorganic_fertilizer /// 
				crop_shock hh_shock formal_education_manager /// 
				female_manager hh_electricity_access urban plot_owned self_reported_area {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
		
	}
	
* encode aez 
	encode 		agro_ecological_zone, gen(aez)
	
* generate dummy for aez

	levelsof 	aez, local(aez_levels)

	foreach 	aez_code in `aez_levels' {
    

		local 		aez_label : label (aez) `aez_code'
    
		local 		clean_label = lower("`aez_label'")
		local 		clean_label = subinstr("`clean_label'", "/", "_", .)
		local 		clean_label = subinstr("`clean_label'", "-", "_", .)
		local 		clean_label = subinstr("`clean_label'", " ", "_", .)
		local 		clean_label = subinstr("`clean_label'", "(", "", .)
		local 		clean_label = subinstr("`clean_label'", ")", "", .)
		local 		clean_label = subinstr("`clean_label'", ",", "", .)
		local 		clean_label = subinstr("`clean_label'", ".", "", .)


		if 			inrange(substr("`clean_label'", 1, 1), "0", "9") {
        local 		clean_label = "aez_`clean_label'"
			
			}

		gen 		dzone_`clean_label' = (aez == `aez_code')

	}
	
* generate dummy for crops
	levelsof 	Main_crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (Main_crop == `crop_code') 
	}	
	
* we have to identify the main crop - plot-manager
	bys 	plot_manager_id wave Main_crop: egen value_maincrop = total(harvest_value_cp)
	bys 	plot_manager_id wave (value_maincrop): gen main_crop2 = Main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop
	
	label 	values main_crop Main_crop 
	
* creating missing value indicators at plot level
	drop 		miss_*
	foreach 	var of varlist harvest_value  harvest_transport_cost /// 
				seed_value seed_kg  total_labor_days total_family_labor_days  /// 
				total_hired_labor_days hired_labor_value  plot_area harvest_value_cp  /// 
				seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
			gen 	mi_`var'=1 if `var'==. 
	}
			

	collapse 	(first)  country Country country_dummy* year survey /// 
				month_startseason_calendar month_endseason_calendar /// 
				admin_1* admin_2* admin_3* admin_4* cluster_id main_crop   /// 
				(max) aez dzone_* urban female_manager formal_education_manager /// 
				hh_size   hh_electricity_access  livestock  hh_shock ag_asset_index   /// 
				total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market /// 
				ln_dist_popcenter ln_dist_road ln_elevation ///
				(max) soil_fertility_index   ///
				(sum) harvest_value    harvest_transport_cost    /// 
				(sum) harvest_value_cp seed_value_cp hired_labor_value_constant  /// 
				inorganic_fert_value_con    ///
				(max) strataid intercropped     ///
				(sum) total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value labor_days_nonhired ///
				(sum) plot_area  ///
				(sum) seed_value seed_kg  ///
				(sum) inorganic_fertilizer_value    ///
				(max) inorganic_fertilizer organic_fertilizer  ///
				(max)  used_pesticides indc_* ///
				(max) crop_shock   ///
				(max) plot_owned  irrigated     self_reported_area  ///
				(mean) age_manager    ///
				(first) tot_precip_sd_season temperature_sd_season  /// 
				temperature_min_season temperature_max_season temperature_mean_season  ///
				(count) mi_* /// 
				(count) n_harvest_value = harvest_value   n_seed_value=seed_value  /// 
				n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost  /// 
				n_inorganic_fertilizer_value=inorganic_fertilizer_value   /// 
				n_total_labor_days=total_labor_days  /// 
				n_total_family_labor_days=total_family_labor_days /// 
				n_total_hired_labor_days=total_hired_labor_days /// 
				n_hired_labor_value=hired_labor_value n_plot_area=plot_area /// 
				n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp  /// 
				n_hired_labor_value_constant = hired_labor_value_constant  /// 
				n_inorganic_fert_value_con = inorganic_fert_value_con , by(plot_manager_id wave)
						
		
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value ///	
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value   plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con  {
			replace 	`var'=. if n_`var'==0
			drop 		n_`var'
	} 
	
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value plot_area harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 		miss_`var'=1 if mi_`var'>=1 | `var'==.
			replace 	miss_`var'=0 if mi_`var'==0 
			lab var 	miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
			lab val 	miss_`var' miss_`var'
			drop 		mi_`var'
	}
	

	foreach 	var in harvest_value seed_value seed_kg inorganic_fertilizer_value  /// 
				total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value   harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			replace 	`var'=`var'/plot_area
		} 
	 	
	
	foreach 	var in harvest_value  seed_value seed_kg inorganic_fertilizer_value  /// 
				total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value  harvest_value_cp seed_value_cp plot_area /// 
				labor_days_nonhired hired_labor_value_constant inorganic_fert_value_con    {
			gen 		ln_`var'=ln(`var' +1)
			lab var 	ln_`var' "Natural log of `var'"
		}
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	** 17,014 observations dropped
	
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* drop mali 
	drop if 	country == "Mali"
	
	
* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area  /// 
				ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp  /// 
				ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index  /// 
				used_pesticides organic_fertilizer irrigated intercropped crop_shock /// 
				hh_shock livestock hh_size formal_education_manager female_manager /// 
				age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp  /// 
				ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation /// 
				tot_precip_sd_season cluster_id  Country main_crop aez  /// 
				tot_precip_sd_season temperature_sd_season temperature_min_season /// 
				temperature_max_season temperature_mean_season) vce(bootstrap)

				
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


* estimate model 5
	
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp year /// 
				indc_* dzone_* $inputs_cp $controls_cp $geo /// 
				[pw = wgt_adj_surveypop],absorb(plot_manager_id) 
	local lb 	= _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub 	= _b[year] + invttail(e(df_r),0.025)*_se[year]
				
	estimates 	store E
	
	
***********************************************************************
**# 7 - model 6 - cluster 
***********************************************************************	


* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
* generate dummy variables for each country	
	encode 		country, gen(Country)
	
* encode main crop	
	encode 		main_crop, gen(Main_crop)


	label 		define yes_no 0 "No" 1 "Yes"
	
* destring 
	foreach 	var in 	miss_harvest_value_cp livestock used_pesticides /// 
				organic_fertilizer irrigated intercropped inorganic_fertilizer /// 
				crop_shock hh_shock formal_education_manager /// 
				female_manager hh_electricity_access urban plot_owned self_reported_area {
		encode 		`var', gen(`var'_dummy)
		replace 	`var'_dummy = 0 if `var'_dummy == 1
		replace 	`var'_dummy = 1 if `var'_dummy == 2
		label 		values 	`var'_dummy yes_no
		drop 		`var'
		rename		`var'_dummy `var'
		
	}
	
* encode aez 
	encode 		agro_ecological_zone, gen(aez)
	
* generate dummy for aez

	levelsof 	aez, local(aez_levels)

	foreach 	aez_code in `aez_levels' {
    

		local 		aez_label : label (aez) `aez_code'
    
		local 		clean_label = lower("`aez_label'")
		local 		clean_label = subinstr("`clean_label'", "/", "_", .)
		local 		clean_label = subinstr("`clean_label'", "-", "_", .)
		local 		clean_label = subinstr("`clean_label'", " ", "_", .)
		local 		clean_label = subinstr("`clean_label'", "(", "", .)
		local 		clean_label = subinstr("`clean_label'", ")", "", .)
		local 		clean_label = subinstr("`clean_label'", ",", "", .)
		local 		clean_label = subinstr("`clean_label'", ".", "", .)


		if 			inrange(substr("`clean_label'", 1, 1), "0", "9") {
        local 		clean_label = "aez_`clean_label'"
			
			}

		gen 		dzone_`clean_label' = (aez == `aez_code')

	}
	
* generate dummy for crops
	levelsof 	Main_crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (Main_crop == `crop_code') 
	}	
		
* we have to identify the main crop of the hh
	bys 	hh_id wave Main_crop: egen value_maincrop = total(harvest_value_cp)
	bys 	hh_id wave (value_maincrop): gen main_crop2 = Main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop
	
	label 	values main_crop Main_crop 
	
	foreach 	var in harvest_value  total_labor_days total_family_labor_days  /// 
				total_hired_labor_days hired_labor_value seed_value seed_kg /// 
				inorganic_fertilizer_value harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con     {
		replace 	`var'=`var'*plot_area
}

* creating missing value indicators at plot level
	drop 		miss_*
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days  /// 
				hired_labor_value  plot_area harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 	mi_`var'=1 if `var'==. 
	}
				

* collapse the data to a hh level 
	collapse 	(first)  country Country country_dummy* year survey /// 
				month_startseason_calendar month_endseason_calendar admin_1* admin_2* /// 
				admin_3* admin_4* cluster_id main_crop       /// 
				(max) aez dzone_* urban female_manager formal_education_manager /// 
				hh_size hh_electricity_access livestock hh_shock ag_asset_index    /// 
				total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market  /// 
				ln_dist_popcenter ln_dist_road ln_elevation ///
				(max)  soil_fertility_index   ///
				(sum) harvest_value    harvest_transport_cost    /// 
				(sum) harvest_value_cp seed_value_cp hired_labor_value_constant  /// 
				inorganic_fert_value_con    ///
				(max) strataid intercropped     ///
				(sum) total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value labor_days_nonhired ///
				(sum) plot_area  ///
				(sum) seed_value seed_kg  ///
				(sum) inorganic_fertilizer_value    ///
				(max) inorganic_fertilizer organic_fertilizer  ///
				(max)  used_pesticides indc_* ///
				(max) crop_shock   ///
				(max) plot_owned  irrigated     self_reported_area  ///
				(mean) age_manager    ///
				(first) tot_precip_sd_season temperature_sd_season temperature_min_season  /// 
				temperature_max_season temperature_mean_season  ///
				(count) mi_* /// 
				(count) n_harvest_value = harvest_value n_seed_value=seed_value /// 
				n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost  /// 
				n_inorganic_fertilizer_value=inorganic_fertilizer_value   /// 
				n_total_labor_days=total_labor_days /// 
				n_total_family_labor_days=total_family_labor_days /// 
				n_total_hired_labor_days=total_hired_labor_days /// 
				n_hired_labor_value=hired_labor_value n_plot_area=plot_area /// 
				n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp  /// 
				n_hired_labor_value_constant = hired_labor_value_constant /// 
				n_inorganic_fert_value_con = inorganic_fert_value_con , by(hh_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value   plot_area harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con  {
			replace 	`var'=. if n_`var'==0
			drop 		n_`var'
	} 
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value /// 
				seed_kg total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value  plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 		miss_`var'=1 if mi_`var'>=1 | `var'==.
			replace 	miss_`var'=0 if mi_`var'==0 
			lab var 	miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
			lab val 	miss_`var' miss_`var'
			drop 		mi_`var'
	}
						
* we have to identify the main crop by cluster
	bys 	cluster_id wave main_crop: egen value_maincrop = total(harvest_value)
	bys 	cluster_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
	drop 	main_crop 
	rename 	main_crop2 main_crop

	label 	values main_crop Main_crop 
	
* creating missing value indicators at plot level
	foreach 	var of varlist harvest_value harvest_transport_cost seed_value seed_kg /// 
				total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value  plot_area harvest_value_cp seed_value_cp  /// 
				hired_labor_value_constant inorganic_fert_value_con    {
			gen 	mi_`var'=1 if `var'==. 
	}

	drop if cluster_id==. 
				
* collapse the data to cluster level 
	collapse 	(first)  country Country country_dummy* year survey /// 
				month_startseason_calendar month_endseason_calendar admin_1* /// 
				admin_2* admin_3* admin_4* main_crop       /// 
				(max) aez dzone_* urban female_manager formal_education_manager hh_size  /// 
				hh_electricity_access  livestock  hh_shock ag_asset_index   /// 
				total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market /// 
				ln_dist_popcenter ln_dist_road ln_elevation ///
				(max) soil_fertility_index   ///
				(sum) harvest_value    harvest_transport_cost    /// 
				(sum) harvest_value_cp seed_value_cp hired_labor_value_constant  /// 
				inorganic_fert_value_con    ///
				(max) strataid intercropped     ///
				(sum) total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value labor_days_nonhired ///
				(sum) plot_area  ///
				(sum) seed_value seed_kg  ///
				(sum) inorganic_fertilizer_value    ///
				(max) inorganic_fertilizer organic_fertilizer  ///
				(max)  used_pesticides indc_* ///
				(max) crop_shock   ///
				(max) plot_owned  irrigated     self_reported_area  ///
				(mean) age_manager    ///
				(first) tot_precip_sd_season temperature_sd_season temperature_min_season  /// 
				temperature_max_season temperature_mean_season  ///
				(count) mi_* /// 
				(count) n_harvest_value = harvest_value n_seed_value=seed_value /// 
				n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost  /// 
				n_inorganic_fertilizer_value=inorganic_fertilizer_value   /// 
				n_total_labor_days=total_labor_days /// 
				n_total_family_labor_days=total_family_labor_days /// 
				n_total_hired_labor_days=total_hired_labor_days /// 
				n_hired_labor_value=hired_labor_value n_plot_area=plot_area /// 
				n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp  /// 
				n_hired_labor_value_constant = hired_labor_value_constant  /// 
				n_inorganic_fert_value_con = inorganic_fert_value_con , by(cluster_id wave)
						
		
* replace invalid observations with missing values and drop flag variables 
	foreach 	var of varlist harvest_value  seed_value seed_kg total_labor_days  /// 
				total_family_labor_days total_hired_labor_days hired_labor_value   /// 
				plot_area harvest_value_cp seed_value_cp hired_labor_value_constant /// 
				inorganic_fert_value_con  {
			replace 	`var'=. if n_`var'==0
			drop 		n_`var'
	}
	*** (count) does not count missing values	
	*** if n_`var' == 0, it means that all values of a variable are missing in that household.


* flag variables with plots containing one or more missing observations
	foreach 	var of varlist harvest_value seed_value seed_kg total_labor_days /// 
				total_family_labor_days total_hired_labor_days hired_labor_value  /// 
				plot_area harvest_value_cp seed_value_cp hired_labor_value_constant  /// 
				inorganic_fert_value_con    {
			gen 		miss_`var'=1 if mi_`var'>=1 | `var'==.
			replace 	miss_`var'=0 if mi_`var'==0 
			lab var 	miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
			lab val 	miss_`var' miss_`var'
			drop 		mi_`var'
	}

*** we scale for effective inputs/outputs
	foreach 	var in harvest_value  seed_value seed_kg inorganic_fertilizer_value  ///
				total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value   harvest_value_cp seed_value_cp /// 
				hired_labor_value_constant inorganic_fert_value_con  {
			replace 	`var'=`var'/plot_area
		} 
				
* generate new variables containing ln of the original variable
	foreach 	var in harvest_value  seed_value seed_kg inorganic_fertilizer_value  ///
				total_labor_days total_family_labor_days total_hired_labor_days /// 
				hired_labor_value  harvest_value_cp seed_value_cp plot_area /// 
				labor_days_nonhired hired_labor_value_constant inorganic_fert_value_con    {
			gen 		ln_`var'=ln(`var' +1)
			lab var 	ln_`var' "Natural log of `var'"
		}
				
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	*** dropped 6 
	
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	
	drop 		scalar temp_weight_test
	
				
* survey design
	svyset 		ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_harvest_value_cp year ln_plot_area  /// 
				ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp  /// 
				ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index  /// 
				used_pesticides organic_fertilizer irrigated intercropped crop_shock /// 
				hh_shock livestock hh_size formal_education_manager female_manager /// 
				age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp  /// 
				ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation /// 
				tot_precip_sd_season cluster_id  Country main_crop aez  /// 
				tot_precip_sd_season temperature_sd_season temperature_min_season /// 
				temperature_max_season temperature_mean_season) vce(bootstrap)

				
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
	
* estimate model 6
	bs4rw, 		rw(bsw*)  : areg ln_harvest_value_cp year /// 
				indc_* dzone_* $inputs_cp $controls_cp $geo /// 
				[pw = wgt_adj_surveypop],absorb(ea) // many reps fail due to collinearities in controls

	estimates 	store F

		
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

			eeeeee	
***********************************************************************
**# 9 - country-level results
***********************************************************************
	
* open dataset
	use 		"$data/countries/aggregate/lsms_zenodo.dta", clear
	
	
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

				
		
