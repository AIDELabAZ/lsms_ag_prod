* Project: LSMS_ag_prod 
* Created on: May 2025
* Created by: rg
* Edited on: 10 June 25
* Edited by: rg
* Stata v.18.0, mac

* does
	* run country-level results:
		* Models 1 and 2
		
* NOTES:
	* run all_models_chirps_main.do BEFORE this 
	* I created two graph separated for each model at country-level /// 
	and then merged them together MANUALLY

***********************************************************************
**# j - country-level results - main 
***********************************************************************				
				
* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear
	
* rename variable
	rename 		agro_ecological_zone aez
		
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
	
* merge with hh 
	merge 		m:1 wave survey country hh_id_obs using ///
				"$export1/dta_files_merge/hh_included.dta"
				
	drop if 	_merge == 1
		
	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 2,744 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a
	* 49 changes
	
* scale inputs
	foreach 	var in total_labor_days seed_value_cp fert_value_cp {
			gen 	`var'_scale = `var' / plot_area_GPS
			drop 	`var'
			rename 	`var'_scale `var'	
	}
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	gen 		ln_total_labor_days = asinh(total_labor_days)
	gen 		ln_seed_value_cp = asinh(seed_value_cp)	
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	gen			ln_fert_value_cp = asinh(fert_value_cp)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	gen 		ln_elevation = asinh(elevation)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country hh_id_obs)
 	egen 		plot_manager_id = group(country manager_id_obs)
	egen 		plot_id = group(country plot_id_obs)
	egen 		parcel_id = group(country parcel_id_obs)
	egen 		cluster_id = group(lat_mod lon_modified)
	
* divide hh weight (pw) by number of plots 
	gen 		pw_plot = pw / nb_plot
	
	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (crop == `crop_code') 
	}	
	
*loop over each country : model 1
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	* set survey design 
	svyset 		ea_id_obs [pweight = pw_plot], strata(strata) singleunit(centered)	
	
	* model 1
	eststo: svy: 		reg ln_yield_cp c.year if country=="`country'" 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	
	
	*outreg2		using "$export1/tables/country_level/yield_country_zenodo.tex", /// 
				keep(c.year country_dummy*) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, country FE, YES)  append
	}				

	esttab  ///
			using "$export1/tables/country_level/yield_country_main_m1.tex", replace r2 ///
			title("Country level results") ///
			nonumber mtitles("Ethiopia" "Malawi" "Mali" "Niger" "Nigeria" "Tanzania") ///
			keep(year* ) ///
			coeflabel (year "Model 1: Annual Time Trend") /// 
			star(* 0.10 * 0.05 ** 0.01) /// 
			ci nonumber 
			
eststo clear 			
*loop over each country : model 2
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	* set survey design 
	svyset 		ea_id_obs [pweight = pw_plot], strata(strata) singleunit(centered)	
	
	* model 2
	eststo: svy: 		reg ln_yield_cp $selbaseline_4_5_6_chirps if country == "`country'" 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	
	
	*outreg2		using "$export1/tables/country_level/yield_country_zenodo.tex", /// 
				keep(c.year country_dummy*) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, country FE, YES)  append
	}				

	esttab  ///
			using "$export1/tables/country_level/yield_country_main_m2.tex", replace r2 ///
			title("Country level results") ///
			nonumber mtitles("Ethiopia" "Malawi" "Mali" "Niger" "Nigeria" "Tanzania") ///
			keep(year* ) ///
			coeflabel (year "Model 2: Annual Time Trend") /// 
			star(* 0.10 * 0.05 ** 0.01) /// 
			ci nonumber 
			
			
			
	eststo clear
			
			
			
***********************************************************************
**# j - country-level results - leaving missing values as missing - top 5%
***********************************************************************			
				
* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp_mss.dta", clear
	
* rename variable
	rename 		agro_ecological_zone aez
		
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
	
* merge with hh 
	merge 		m:1 wave survey country hh_id_obs using ///
				"$export1/dta_files_merge/hh_included_mss.dta"
				
	drop if 	_merge == 1
		
	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 2,744 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a
	* 49 changes
	
* scale inputs
	foreach 	var in total_labor_days seed_value_cp fert_value_cp {
			gen 	`var'_scale = `var' / plot_area_GPS
			drop 	`var'
			rename 	`var'_scale `var'	
	}
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	gen 		ln_total_labor_days = asinh(total_labor_days)
	gen 		ln_seed_value_cp = asinh(seed_value_cp)	
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	gen			ln_fert_value_cp = asinh(fert_value_cp)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	gen 		ln_elevation = asinh(elevation)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country hh_id_obs)
 	egen 		plot_manager_id = group(country manager_id_obs)
	egen 		plot_id = group(country plot_id_obs)
	egen 		parcel_id = group(country parcel_id_obs)
	egen 		cluster_id = group(lat_mod lon_modified)
	
* divide hh weight (pw) by number of plots 
	gen 		pw_plot = pw / nb_plot
	
	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (crop == `crop_code') 
	}	
	
*loop over each country : model 1
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	* set survey design 
	svyset 		ea_id_obs [pweight = pw_plot], strata(strata) singleunit(centered)	
	
	* model 1
	eststo: svy: 		reg ln_yield_cp c.year if country=="`country'" 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	
	
	*outreg2		using "$export1/tables/country_level/yield_country_zenodo.tex", /// 
				keep(c.year country_dummy*) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, country FE, YES)  append
	}				

	esttab  ///
			using "$export1/tables/country_level/yield_country_m1_mss.tex", replace r2 ///
			title("Country level results") ///
			nonumber mtitles("Ethiopia" "Malawi" "Mali" "Niger" "Nigeria" "Tanzania") ///
			keep(year* ) ///
			coeflabel (year "Model 1: Annual Time Trend") /// 
			star(* 0.10 * 0.05 ** 0.01) /// 
			ci nonumber 
			
eststo clear 			
*loop over each country : model 2
	foreach 	country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	* set survey design 
	svyset 		ea_id_obs [pweight = pw_plot], strata(strata) singleunit(centered)	
	
	* model 2
	eststo: svy: 		reg ln_yield_cp $selbaseline_4_5_6_chirps if country == "`country'" 

	local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	
	
	*outreg2		using "$export1/tables/country_level/yield_country_zenodo.tex", /// 
				keep(c.year country_dummy*) /// 
				ctitle("Geovariables and weather controls") addstat(  Upper bound CI, /// 
				`ub', Lower bound CI, `lb') addtext(Main crop FE, YES, country FE, YES)  append
	}				

	esttab  ///
			using "$export1/tables/country_level/yield_country_m2_mss.tex", replace r2 ///
			title("Country level results") ///
			nonumber mtitles("Ethiopia" "Malawi" "Mali" "Niger" "Nigeria" "Tanzania") ///
			keep(year* ) ///
			coeflabel (year "Model 2: Annual Time Trend") /// 
			star(* 0.10 * 0.05 ** 0.01) /// 
			ci nonumber 
