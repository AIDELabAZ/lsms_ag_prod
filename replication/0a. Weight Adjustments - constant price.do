

* Calculate weight and define strata for cross country analysis 
use "${Clean}/Final/LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1\SCIENCE - analysis\Manuscript\Prep/0b. Pre-Analysis - constant price.do" 

drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)


// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

drop nb_plot   temp_weight_surveypop sum_weight_wave_surveypop  

save "${Paper1_temp}/weights_adj1_cp_ARCHIVE.dta", replace 

/*
** FARMER LEVEL

use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear


foreach var in harvest_value harvest_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_12months land_value_agseason seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value pesticide_value fungicide_value harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp{
		replace `var'=`var'*plot_area
}


*** Creating a new "main crop" variable 
bys plot_manager_id wave main_crop: egen value_maincrop = total(harvest_value)
bys plot_manager_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop

*** Counting missing values
drop miss_*
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		gen mi_`var'=1 if `var'==. 
	}

** Aggregating
collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1 admin_2 admin_3 admin_4 cluster_id main_crop  strataid ea season_length total_wgt_survey /// 
		 (max) agro_ecological_zone urban female_manager  married_manager primary_education_manager formal_education_manager hh_size hh_formal_education hh_primary_education hh_electricity_access hh_dependency_ratio livestock   female_respondent married_respondent primary_education_respondent formal_education_respondent hh_shock ag_asset_index hh_asset_index   pw ///
		 (mean) dist_road dist_market dist_popcenter slope elevation soil_fertility_index twi ///
			(min) harvest_interview_month planting_interview_month ///
			(min) planting_month (max) harvest_end_month  ///
			(sum) harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost   /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp ///
			(max) intercropped perennial_crops  ///
			(max) wheat_plot  sorghum_plot  maize_plot  ///
			(sum) wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) land_value_agseason land_value_12months plot_area  ///
			(sum) seed_value seed_kg seed_transport_cost (max) improved ///
			(sum) inorganic_fertilizer_value nitrogen_kg fertilizer_transport_cost  ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max) used_herbicides used_pesticides  ///
			(sum) herbicide_value pesticide_value fungicide_value ///
		    (max) crop_shock drought_shock rain_shock pests_shock harvest_unfinished ///
			(max) plot_owned plot_certificate irrigated erosion fallow tractor  ///
			(mean) age_manager age_respondent ///
			(first) tot_precip_sd_season* tot_precip_min_season* tot_precip_max_season* temperature_sd_season* temperature_min_season* temperature_max_season* temperature_mean_season* temperature_above25C_season* temperature_above30C_season* temperature_above35C_season* temperature_below15C_season* temperature_LRmean_season* temperature_lagP_av3months* temperature_lagP_av6months*  temperature_meanmonth_lag1P* temperature_meanmonth_lag2P* temperature_meanmonth_lag3P* temperature_meanmonth_lead1P* temperature_meanmonth_lead2P* temperature_meanmonth_lead3P* temp_meanmonthH* temperature_meanmonthP* tot_precip_cumul_season* tot_precip_below5p_season* tot_precip_below1p_season* tot_precip_0precip_season* tot_precip_above95p_season* tot_precip_above99p_season* tot_precip_LRmean_season* tot_precip_lagP_cumul3months* tot_precip_lagP_cumul6months* tot_precip_cumulmonth_lag1P* tot_precip_cumulmonth_lag2P* tot_precip_cumulmonth_lag3P* tot_precip_cumulmonth_lead1P* tot_precip_cumulmonth_lead2P* tot_precip_cumulmonth_lead3P* tot_precip_cumulmonthH* tot_precip_cumulmonthP* temperature_meanmonth_lag1H* temperature_meanmonth_lag2H* temperature_meanmonth_lag3H* temperature_meanmonth_lag4H* temperature_meanmonth_lag5H* temperature_meanmonth_lag6H* tot_precip_cumulmonth_lag1H* tot_precip_cumulmonth_lag2H* tot_precip_cumulmonth_lag3H* tot_precip_cumulmonth_lag4H* tot_precip_cumulmonth_lag5H* tot_precip_cumulmonth_lag6H* temperature_maxmax_season* temperature_maxmin_season* temperature_minmax_season* temperature_minmin_season* temperature_maxrange_season* precipitation_maxmax_season* max_5day_precip_season* pii_season* days_above_10mm_season* days_above_20mm_season* dry_spell_season* wet_spell_season ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value n_harvest_value_expected = harvest_value_expected n_harvest_kg=harvest_kg n_harvest_kg_expected = harvest_kg_expected n_seed_value=seed_value n_seed_kg=seed_kg n_seed_transport_cost=seed_transport_cost n_harvest_transport_cost= harvest_transport_cost  n_inorganic_fertilizer_value=inorganic_fertilizer_value n_nitrogen_kg=nitrogen_kg n_fertilizer_transport_cost=fertilizer_transport_cost n_herbicide_value=herbicide_value n_pesticide_value=pesticide_value n_fungicide_value=fungicide_value n_wheat_kg=wheat_kg n_sorghum_kg=sorghum_kg n_maize_kg=maize_kg n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_land_value_agseason=land_value_agseason  n_land_value_12months=land_value_12months n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con n_pesticide_value_cp = pesticide_value_cp n_herbicide_value_cp = herbicide_value_cp n_fungicide_value_cp = fungicide_value_cp, by(plot_manager_id wave)
				
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		replace `var'=. if n_`var'==0
		drop n_`var'
	}
	
	
*** We create variables flagging the existence of missing values within plots
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}
	

*** we scale for effective inputs/outputs

 foreach var in harvest_value harvest_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_12months land_value_agseason seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value pesticide_value fungicide_value harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		replace `var'=`var'/plot_area
		} 
	 
	
	foreach var in harvest_value harvest_kg  seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value fungicide_value pesticide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp    {
		gen ln_`var'=ln(`var' +1)
		lab var ln_`var' "Natural log of `var'"
		
}		
gen ln_plot_area = ln(plot_area)

gen total_labor_days_nonhired = total_labor_days -  total_hired_labor_days
	gen year =  year(dofm(month_endseason_calendar))
	encode country, gen(Country)
	tabulate Country, generate(country_dummy) 
	encode main_crop, gen(Main_crop)
	gen ln_labor_days_nonhired = ln(total_labor_days_nonhired + 1)
gen ln_dist_road= ln(dist_road +1)
	gen ln_dist_market = ln(dist_market +1)
	gen ln_dist_popcenter = ln(dist_popcenter +1)
	gen ln_elevation = ln(elevation +1)
	gen ln_twi = ln(twi +1)
	gen ln_slope = ln(slope +1)
		
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 
	

drop if main_crop=="" | pw==.
// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

save "${Paper1_temp}/weights_adj1_pm.dta", replace 

*** HOUSEHOLD LEVEL

use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear

*** Transformation to total output/inpus instead of effective output/input

foreach var in harvest_value harvest_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_12months land_value_agseason seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value pesticide_value fungicide_value harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp  {
		replace `var'=`var'*plot_area
}


*** Creating a new "main crop" variable 
bys hh_id wave main_crop: egen value_maincrop = total(harvest_value)
bys hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop

*** Counting missing values
drop miss_*
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		gen mi_`var'=1 if `var'==. 
	}

** Aggregating
collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1 admin_2 admin_3 admin_4 cluster_id main_crop ea season_length  /// 
		 (max) agro_ecological_zone urban female_manager married_manager primary_education_manager formal_education_manager hh_size hh_formal_education hh_primary_education hh_electricity_access hh_dependency_ratio livestock female_respondent married_respondent primary_education_respondent formal_education_respondent hh_shock ag_asset_index hh_asset_index total_wgt_survey pw ///
		 (mean) dist_road dist_market dist_popcenter slope elevation soil_fertility_index twi ///
			(min) harvest_interview_month planting_interview_month ///
			(min) planting_month (max) harvest_end_month  ///
			(sum) harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost  /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp ///
			(max) strataid intercropped perennial_crops  ///
			(max) wheat_plot  sorghum_plot  maize_plot  ///
			(sum) wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) land_value_agseason land_value_12months plot_area  ///
			(sum) seed_value seed_kg seed_transport_cost (max) improved ///
			(sum) inorganic_fertilizer_value nitrogen_kg fertilizer_transport_cost  ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max) used_herbicides used_pesticides  ///
			(sum) herbicide_value pesticide_value fungicide_value ///
		    (max) crop_shock drought_shock rain_shock pests_shock harvest_unfinished ///
			(max) plot_owned plot_certificate irrigated erosion fallow tractor ///
			(mean) age_manager age_respondent  ///
			(first) tot_precip_sd_season* tot_precip_min_season* tot_precip_max_season* temperature_sd_season* temperature_min_season* temperature_max_season* temperature_mean_season* temperature_above25C_season* temperature_above30C_season* temperature_above35C_season* temperature_below15C_season* temperature_LRmean_season* temperature_lagP_av3months* temperature_lagP_av6months* temperature_meanmonth_lag1P* temperature_meanmonth_lag2P* temperature_meanmonth_lag3P* temperature_meanmonth_lead1P* temperature_meanmonth_lead2P* temperature_meanmonth_lead3P* temp_meanmonthH* temperature_meanmonthP* tot_precip_cumul_season* tot_precip_below5p_season* tot_precip_below1p_season* tot_precip_0precip_season* tot_precip_above95p_season* tot_precip_above99p_season* tot_precip_LRmean_season* tot_precip_lagP_cumul3months* tot_precip_lagP_cumul6months* tot_precip_cumulmonth_lag1P* tot_precip_cumulmonth_lag2P* tot_precip_cumulmonth_lag3P* tot_precip_cumulmonth_lead1P* tot_precip_cumulmonth_lead2P* tot_precip_cumulmonth_lead3P* tot_precip_cumulmonthH* tot_precip_cumulmonthP* temperature_meanmonth_lag1H* temperature_meanmonth_lag2H* temperature_meanmonth_lag3H* temperature_meanmonth_lag4H* temperature_meanmonth_lag5H* temperature_meanmonth_lag6H* tot_precip_cumulmonth_lag1H* tot_precip_cumulmonth_lag2H* tot_precip_cumulmonth_lag3H* tot_precip_cumulmonth_lag4H* tot_precip_cumulmonth_lag5H* tot_precip_cumulmonth_lag6H* temperature_maxmax_season* temperature_maxmin_season* temperature_minmax_season* temperature_minmin_season* temperature_maxrange_season* precipitation_maxmax_season* max_5day_precip_season* pii_season* days_above_10mm_season* days_above_20mm_season* dry_spell_season* wet_spell_season* ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value n_harvest_value_expected = harvest_value_expected n_harvest_kg=harvest_kg n_harvest_kg_expected = harvest_kg_expected n_seed_value=seed_value n_seed_kg=seed_kg n_seed_transport_cost=seed_transport_cost n_harvest_transport_cost= harvest_transport_cost  n_inorganic_fertilizer_value=inorganic_fertilizer_value n_nitrogen_kg=nitrogen_kg n_fertilizer_transport_cost=fertilizer_transport_cost n_herbicide_value=herbicide_value n_pesticide_value=pesticide_value n_fungicide_value=fungicide_value n_wheat_kg=wheat_kg n_sorghum_kg=sorghum_kg n_maize_kg=maize_kg n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_land_value_agseason=land_value_agseason  n_land_value_12months=land_value_12months n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con n_pesticide_value_cp = pesticide_value_cp n_herbicide_value_cp = herbicide_value_cp n_fungicide_value_cp = fungicide_value_cp, by(hh_id wave)
	
	
			
				
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		replace `var'=. if n_`var'==0
		drop n_`var'
	}
	
	
*** We create variables flagging the existence of missing values within plots
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}
	


*** we scale for effective inputs/outputs

 foreach var in harvest_value harvest_kg  seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value fungicide_value pesticide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp   {
		replace `var'=`var'/plot_area
		} 
	 

*** We add logs 
	
egen harvest_value_per = rowtotal(harvest_value )
	
	foreach var in harvest_value harvest_kg  seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value fungicide_value pesticide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp   harvest_value_per {
		gen ln_`var'=ln(`var' +1)
		lab var ln_`var' "Natural log of `var'"
		}

	
	gen ln_plot_area = ln(plot_area)
	
*** Create extra variables for analysis
	gen total_labor_days_nonhired = total_labor_days -  total_hired_labor_days
	gen year =  year(dofm(month_endseason_calendar))
	encode country, gen(Country)
	tabulate Country, generate(country_dummy) 
	encode main_crop, gen(Main_crop)
	gen ln_labor_days_nonhired = ln(total_labor_days_nonhired + 1)
gen ln_dist_road= ln(dist_road +1)
	gen ln_dist_market = ln(dist_market +1)
	gen ln_dist_popcenter = ln(dist_popcenter +1)
	gen ln_elevation = ln(elevation +1)
	gen ln_twi = ln(twi +1)
	gen ln_slope = ln(slope +1)
	
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 
	
// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

save "${Paper1_temp}/weights_adj1_hh.dta", replace

*** Cluster level dataset

use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear

*** Transformation to total output/inpus instead of effective output/input

foreach var in harvest_value harvest_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_12months land_value_agseason seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value pesticide_value fungicide_value harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp  {
		replace `var'=`var'*plot_area
}


*** Creating a new "main crop" variable 
bys hh_id wave main_crop: egen value_maincrop = total(harvest_value)
bys hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop

*** Counting missing values
drop miss_*
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		gen mi_`var'=1 if `var'==. 
	}

** Aggregating
collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1 admin_2 admin_3 admin_4 cluster_id main_crop   ea season_length /// 
		 (max) agro_ecological_zone urban female_manager  married_manager primary_education_manager formal_education_manager hh_size hh_formal_education hh_primary_education hh_electricity_access hh_dependency_ratio livestock   female_respondent married_respondent primary_education_respondent formal_education_respondent hh_shock ag_asset_index hh_asset_index  total_wgt_survey pw ///
		 (mean) dist_road dist_market dist_popcenter slope elevation soil_fertility_index twi ///
			(min) harvest_interview_month planting_interview_month ///
			(min) planting_month (max) harvest_end_month  ///
			(sum) harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost  /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp ///
			(max) strataid intercropped perennial_crops  ///
			(max) wheat_plot  sorghum_plot  maize_plot  ///
			(sum) wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) land_value_agseason land_value_12months plot_area  ///
			(sum) seed_value seed_kg seed_transport_cost (max) improved ///
			(sum) inorganic_fertilizer_value nitrogen_kg fertilizer_transport_cost  ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max) used_herbicides used_pesticides  ///
			(sum) herbicide_value pesticide_value fungicide_value ///
		    (max) crop_shock drought_shock rain_shock pests_shock harvest_unfinished ///
			(max) plot_owned plot_certificate irrigated erosion fallow tractor ///
			(mean) age_manager age_respondent  ///
			(first) tot_precip_sd_season* tot_precip_min_season* tot_precip_max_season* temperature_sd_season* temperature_min_season* temperature_max_season* temperature_mean_season* temperature_above25C_season* temperature_above30C_season* temperature_above35C_season* temperature_below15C_season* temperature_LRmean_season* temperature_lagP_av3months* temperature_lagP_av6months* temperature_meanmonth_lag1P* temperature_meanmonth_lag2P* temperature_meanmonth_lag3P* temperature_meanmonth_lead1P* temperature_meanmonth_lead2P* temperature_meanmonth_lead3P* temp_meanmonthH* temperature_meanmonthP* tot_precip_cumul_season* tot_precip_below5p_season* tot_precip_below1p_season* tot_precip_0precip_season* tot_precip_above95p_season* tot_precip_above99p_season* tot_precip_LRmean_season* tot_precip_lagP_cumul3months* tot_precip_lagP_cumul6months* tot_precip_cumulmonth_lag1P* tot_precip_cumulmonth_lag2P* tot_precip_cumulmonth_lag3P* tot_precip_cumulmonth_lead1P* tot_precip_cumulmonth_lead2P* tot_precip_cumulmonth_lead3P* tot_precip_cumulmonthH* tot_precip_cumulmonthP* temperature_meanmonth_lag1H* temperature_meanmonth_lag2H* temperature_meanmonth_lag3H* temperature_meanmonth_lag4H* temperature_meanmonth_lag5H* temperature_meanmonth_lag6H* tot_precip_cumulmonth_lag1H* tot_precip_cumulmonth_lag2H* tot_precip_cumulmonth_lag3H* tot_precip_cumulmonth_lag4H* tot_precip_cumulmonth_lag5H* tot_precip_cumulmonth_lag6H* temperature_maxmax_season* temperature_maxmin_season* temperature_minmax_season* temperature_minmin_season* temperature_maxrange_season* precipitation_maxmax_season* max_5day_precip_season* pii_season* days_above_10mm_season* days_above_20mm_season* dry_spell_season* wet_spell_season* ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value n_harvest_value_expected = harvest_value_expected n_harvest_kg=harvest_kg n_harvest_kg_expected = harvest_kg_expected n_seed_value=seed_value n_seed_kg=seed_kg n_seed_transport_cost=seed_transport_cost n_harvest_transport_cost= harvest_transport_cost  n_inorganic_fertilizer_value=inorganic_fertilizer_value n_nitrogen_kg=nitrogen_kg n_fertilizer_transport_cost=fertilizer_transport_cost n_herbicide_value=herbicide_value n_pesticide_value=pesticide_value n_fungicide_value=fungicide_value n_wheat_kg=wheat_kg n_sorghum_kg=sorghum_kg n_maize_kg=maize_kg n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_land_value_agseason=land_value_agseason  n_land_value_12months=land_value_12months n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con n_pesticide_value_cp = pesticide_value_cp n_herbicide_value_cp = herbicide_value_cp n_fungicide_value_cp = fungicide_value_cp, by(hh_id wave)
				
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		replace `var'=. if n_`var'==0
		drop n_`var'
	}
	
	
*** We create variables flagging the existence of missing values within plots
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}
	


*** Creating a new "main crop" variable 
bys cluster_id wave main_crop: egen value_maincrop = total(harvest_value)
bys cluster_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop

*** Counting missing values
drop mi_*
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		gen mi_`var'=1 if `var'==. 
	}

drop if cluster_id==. 
collapse  (first)  country survey month_startseason_calendar month_endseason_calendar admin_1 admin_2 admin_3 admin_4 main_crop  season_length  /// 
		 (max) agro_ecological_zone total_wgt_survey  strataid  ea ///
		 (mean) dist_road dist_market dist_popcenter slope elevation soil_fertility_index twi ///
			(min) harvest_interview_month planting_interview_month ///
			(min) planting_month (max) harvest_end_month  ///
			(sum) pw  harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost   /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp ///
			(max) intercropped perennial_crops  ///
			(max) wheat_plot  sorghum_plot  maize_plot  ///
			(sum) wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) land_value_agseason land_value_12months plot_area  ///
			(sum) seed_value seed_kg seed_transport_cost (max) improved ///
			(sum) inorganic_fertilizer_value nitrogen_kg fertilizer_transport_cost  ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max) used_herbicides used_pesticides  ///
			(sum) herbicide_value pesticide_value fungicide_value ///
		    (max) crop_shock drought_shock rain_shock pests_shock harvest_unfinished ///
			(max) plot_owned plot_certificate irrigated erosion fallow tractor ///
			(mean) age_manager age_respondent hh_size hh_formal_education hh_primary_education hh_electricity_access hh_dependency_ratio livestock  female_manager  married_manager primary_education_manager formal_education_manager female_respondent married_respondent primary_education_respondent formal_education_respondent hh_shock ag_asset_index hh_asset_index urban ///
			(first) tot_precip_sd_season* tot_precip_min_season* tot_precip_max_season* temperature_sd_season* temperature_min_season* temperature_max_season* temperature_mean_season* temperature_above25C_season* temperature_above30C_season* temperature_above35C_season* temperature_below15C_season* temperature_LRmean_season* temperature_lagP_av3months* temperature_lagP_av6months* temperature_meanmonth_lag1P* temperature_meanmonth_lag2P* temperature_meanmonth_lag3P* temperature_meanmonth_lead1P* temperature_meanmonth_lead2P* temperature_meanmonth_lead3P* temp_meanmonthH* temperature_meanmonthP* tot_precip_cumul_season* tot_precip_below5p_season* tot_precip_below1p_season* tot_precip_0precip_season* tot_precip_above95p_season* tot_precip_above99p_season* tot_precip_LRmean_season* tot_precip_lagP_cumul3months* tot_precip_lagP_cumul6months* tot_precip_cumulmonth_lag1P* tot_precip_cumulmonth_lag2P* tot_precip_cumulmonth_lag3P* tot_precip_cumulmonth_lead1P* tot_precip_cumulmonth_lead2P* tot_precip_cumulmonth_lead3P* tot_precip_cumulmonthH* tot_precip_cumulmonthP* temperature_meanmonth_lag1H* temperature_meanmonth_lag2H* temperature_meanmonth_lag3H* temperature_meanmonth_lag4H* temperature_meanmonth_lag5H* temperature_meanmonth_lag6H* tot_precip_cumulmonth_lag1H* tot_precip_cumulmonth_lag2H* tot_precip_cumulmonth_lag3H* tot_precip_cumulmonth_lag4H* tot_precip_cumulmonth_lag5H* tot_precip_cumulmonth_lag6H* temperature_maxmax_season* temperature_maxmin_season* temperature_minmax_season* temperature_minmin_season* temperature_maxrange_season* precipitation_maxmax_season* max_5day_precip_season* pii_season* days_above_10mm_season* days_above_20mm_season* dry_spell_season* wet_spell_season* ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value n_harvest_value_expected = harvest_value_expected n_harvest_kg=harvest_kg n_harvest_kg_expected = harvest_kg_expected n_seed_value=seed_value n_seed_kg=seed_kg n_seed_transport_cost=seed_transport_cost n_harvest_transport_cost= harvest_transport_cost  n_inorganic_fertilizer_value=inorganic_fertilizer_value n_nitrogen_kg=nitrogen_kg n_fertilizer_transport_cost=fertilizer_transport_cost n_herbicide_value=herbicide_value n_pesticide_value=pesticide_value n_fungicide_value=fungicide_value n_wheat_kg=wheat_kg n_sorghum_kg=sorghum_kg n_maize_kg=maize_kg n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_land_value_agseason=land_value_agseason  n_land_value_12months=land_value_12months n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con n_pesticide_value_cp = pesticide_value_cp n_herbicide_value_cp = herbicide_value_cp n_fungicide_value_cp = fungicide_value_cp n_pw=pw, by(cluster_id wave)
			
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp pw {
		replace `var'=. if n_`var'==0
		drop n_`var'
	}
	
	
*** We create variables flagging the existence of missing values within clusters
	foreach var of varlist harvest_value harvest_kg harvest_value_expected harvest_kg_expected harvest_transport_cost seed_value seed_kg seed_transport_cost herbicide_value pesticide_value fungicide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}

*** we scale for effective inputs/outputs

 foreach var in harvest_value harvest_kg  seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value fungicide_value pesticide_value wheat_kg sorghum_kg maize_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_agseason land_value_12months harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp {
		replace `var'=`var'/plot_area
		} 
	 

*** We add logs
	foreach var in harvest_value harvest_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value land_value_12months land_value_agseason seed_value seed_kg inorganic_fertilizer_value nitrogen_kg herbicide_value pesticide_value fungicide_value harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con pesticide_value_cp herbicide_value_cp fungicide_value_cp  {
		gen ln_`var'=ln(`var' +1)
		lab var ln_`var' "Natural log of `var'"
		}	
	
	gen ln_plot_area = ln(plot_area)
	
*** Create extra variables for analysis
	gen total_labor_days_nonhired = total_labor_days -  total_hired_labor_days
	gen year =  year(dofm(month_endseason_calendar))
	encode country, gen(Country)
	tabulate Country, generate(country_dummy) 
	encode main_crop, gen(Main_crop)
	gen ln_labor_days_nonhired = ln(total_labor_days_nonhired + 1)
gen ln_dist_road= ln(dist_road +1)
	gen ln_dist_market = ln(dist_market +1)
	gen ln_dist_popcenter = ln(dist_popcenter +1)
	gen ln_elevation = ln(elevation +1)
	gen ln_twi = ln(twi +1)
	gen ln_slope = ln(slope +1)
	gen full_losses = 1 if harvest_value_cp==0
		replace full_losses = 0 if harvest_value_cp> 0 & !mi(harvest_value_cp)
		

	
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 
	

bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)			
					

save "${Paper1_temp}/weights_adj1_cluster.dta", replace

** Drop categories


forvalues x = 1/10 {
	
use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 

drop if contains_crop_`x'==1

drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

save "${Paper1_temp}/weights_adj1_withoutcrop`x'.dta", replace 
}

*** Plot & farm chars

use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 

preserve 
drop if female_manager==1 
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_fem1.dta", replace 
restore


preserve 
drop if female_manager==0
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_fem0.dta", replace 
restore


preserve 
drop if formal_education_manager==1 
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_fedu1.dta", replace 
restore


preserve 
drop if formal_education_manager==0
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_fedu0.dta", replace 
restore

preserve 
drop if urban==0
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_urb0.dta", replace 
restore

preserve 
drop if urban==1
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_urb1.dta", replace 
restore

gen manager_under30 = 1 if age_manager<30
replace manager_under30 = 0 if age_manager>30

preserve 
drop if manager_under30==1
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_u30_1.dta", replace 
restore


preserve 
drop if manager_under30==0
drop if main_crop==""
bys country survey wave hh_id  : egen nb_plot = count(plot_id)

// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_u30_0.dta", replace 
restore


*** Balanced panel

use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 

keep hh_id wave country 
duplicates drop
egen nb_obs1 = total(inlist(wave, 1, 2, 3)) if country=="Ethiopia", by(hh_id)
egen nb_obs2 = total(inlist(wave, 1, 2, 3, 4)) if country=="Malawi" | country=="Nigeria", by(hh_id)
egen nb_obs3 = total(inlist(wave, 1, 2)) if country=="Niger" | country=="Mali", by(hh_id)
egen nb_obs4 = total(inlist(wave, 1, 2, 3, 4, 5)) if country=="Tanzania", by(hh_id)
egen nb_obs = rowmax(nb_obs*)
drop nb_obs1 nb_obs2 nb_obs3 nb_obs4
drop if country=="Ethiopia" & nb_obs!=3 
drop if country=="Malawi" & nb_obs!=4  | country=="Nigeria" & nb_obs!=4
drop if country=="Niger" & nb_obs!=2  | country=="Mali" & nb_obs!=2
drop if country=="Tanzania" & nb_obs!=5
keep hh_id 
duplicates drop
save "${Temp}/All countries/Balanced panel IDs.dta", replace


use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 

merge m:1 hh_id using "${Temp}/All countries/Balanced panel IDs.dta"
drop if _merge==1

bys country survey wave hh_id  : egen nb_plot = count(plot_id)


// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_balancedpanel.dta", replace 


** Winsorisation (trim)


use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 

foreach var of varlist ln_harvest_value_cp {
winsor2 `var' if `var'>0 , cuts(1 99) trim 
}
bys country survey wave hh_id  : egen nb_plot = count(plot_id)
// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_trim99.dta", replace 



use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 


foreach var of varlist ln_harvest_value_cp {
winsor2 `var' if `var'>0 , cuts(1 95) trim 
}
bys country survey wave hh_id  : egen nb_plot = count(plot_id)
// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_trim95.dta", replace 


use "${Clean}/Final/LSMS_mega_panel_nominal$.dta", clear
do "${Do}/1. Analysis/Paper 1/Prep/0b. Pre-Analysis - constant price.do" 


foreach var of varlist ln_harvest_value_cp {
winsor2 `var' if `var'>0 , cuts(1 90) trim 
}
bys country survey wave hh_id  : egen nb_plot = count(plot_id)
// Weights summing to total population of combined strata
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
save "${Paper1_temp}/weights_adj1_trim90.dta", replace 
