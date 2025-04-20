* Project: LSMS_ag_prod 
* Created on: april 2025
* Created by: alj
* Edited on: 19 april 2025
* Edited by: alj
* Stata v.18.5

* does
	* tests a bunch of stuff anna tried 

* assumes
	* access to replication data
	
* notes:
	* 
	
***********************************************************************
**# a - setup
***********************************************************************

* define paths	
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	global export1 	"$output/graphs&tables"
	
* open log	
	cap log 		close
	
***********************************************************************
**# b - random stuff 
***********************************************************************

*svy in model 2 bugs 
* error is "no observations"

/* 
no observations
an error occurred when svy executed regress
r(2000); 
*/ 


*** NEED TO RUN PROJECT DO
*** AND THEN SHOULD RUN ZENODO_ALL MODELS 

	distinct 		ln_harvest_value_cp
	distinct 		year
	distinct 		country_dummy*
	distinct 		indc_*
	display 		"$inputs_cp"
	distinct 		ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ///
						ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index
	display 		"$controls_cp"
	distinct		used_pesticides organic_fertilizer irrigated intercropped crop_shock ///
						hh_shock livestock hh_size formal_education_manager female_manager ///
						age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp
	display 		"$geo"
	distinct 		ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation ///
						tot_precip_sd_season agro_ecological_zone temperature_sd_season ///
						temperature_min_season temperature_max_season temperature_mean_season
	
	reg ln_harvest_value_cp year country_dummy* indc_* $inputs_cp $controls_cp $geo
	*** THIS DOES NOT RUN 
	*** SO, issue is with data, not with model ...? 
