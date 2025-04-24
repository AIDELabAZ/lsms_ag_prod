* Project: LSMS_ag_prod 
* Created on: Jan 2025
* Created by: rg
* Edited on: 24 April 25
* Edited by: rg
* Stata v.18.0

* does
	* runs all models using:
		* scaled inputs 
		* includes farm size and nb_plot as controls
		* drops Mali before running models 4 and 5 becase hh and managers /// 
		cannot be tracked over time
		* model 2: loop running lasso for each rf product and saving /// 
		selected vars 

* assumes
	* access to replication data
	
* notes:
	* run time is on the scale of hours?
	* elevation is missing tza 4,5 and niger 2
	* if including tza 1 and 2 - change rf 04 to 03
	
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
**# b - generate  hh_id, plot_manager_id, and cluster_id, main crop
**********************************************************************

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear
	*drop if country == "Tanzania" & (wave == 1 | wave ==2 )
	
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
			
			
* merge hh 
	*merge m:1 	country wave hh_id_obs using "$export1/dta_files_merge/hh_included.dta"

	*keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	*drop 		_merge
	
* merge manager 
	*merge m:1 	country wave hh_id_obs manager_id_obs /// 
				using "$export1/dta_files_merge/manager_included.dta"
	
	*keep if 	_merge == 3 | country == "Mali"
	
	*drop 		_merge
	
* merge cluster 
	*merge m:1 	country wave lat_mod lon_modified /// 
				using "$export1/dta_files_merge/cluster_included.dta"
	
	*keep if 	_merge == 3 
	
		
	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 3,769 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a
	* 55 changes
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country hh_id_obs)
 	egen 		plot_manager_id = group(country manager_id_obs)
	egen 		plot_id = group(country plot_id_obs)
	egen 		parcel_id = group(country parcel_id_obs)
	egen 		cluster_id = group(lat_mod lon_modified)
	

* divide hh weight (pw) by number of plots 
	gen 		pw_plot = pw / nb_plot
	
* create total_wgt_survey varianble 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
		/*
* create weight adj	
	bys 		country wave : egen double sum_weight_wave_surveypop = sum(pw)
	* new variable 
	* pw divided by number of plots
	*bys 	country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
	*** why by survey?
	* new variable that is the sum of the weighted survey just created by plots 
	* ANNA IS CHANGING THIS TO WAVE NOT SURVEY - 25/03
	gen 	double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	* product of the total weight of pw divided by the reweighted sum 
	gen 	double wgt_adj_surveypop = scalar * pw 
	* then muliplied by the outcome of the pw weighted by plots 
	*bys 	country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
	bys 	country wave : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
	*** AS ABOVE 
	assert 	float(temp_weight_test)==float(total_wgt_survey)
	drop 	scalar temp_weight_test

	drop 	sum_weight_wave_surveypop  
	*/
***********************************************************************
**# c - model 1: plot-level
***********************************************************************

* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)

	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	

* no weights 
	*reg 		ln_yield_cp c.year d_* , vce(cluster ea_id_obs)
* run survey-weighted regression 
	*svyset 		ea_id_obs [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	svyset 		ea_id_obs [pweight = pw_plot], strata(strataid) singleunit(centered)


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
**# d - model 2: plot-level
***********************************************************************

* scale inputs
	foreach 	var in total_labor_days seed_value_cp fert_value_cp {
			gen 	`var'_scale = `var' / plot_area_GPS
			drop 	`var'
			rename 	`var'_scale `var'	
	}

* generate log variables for inputs and controls 
	gen 		ln_total_labor_days = asinh(total_labor_days)
	gen 		ln_seed_value_cp = asinh(seed_value_cp)	
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	gen			ln_fert_value_cp = asinh(fert_value_cp)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	gen 		ln_elevation = asinh(elevation)

	
* define input and control globals 
* we include farm size 


	global 		inputs_cp ln_total_labor_days ln_seed_value_cp  ln_fert_value_cp hh_asset_index ag_asset_index
	global 		controls_cp used_pesticides organic_fertilizer irrigated intercropped hh_shock crop_shock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned farm_size nb_plots 
	*** in this global they used miss_harvest_value_cp
	
	global 		geo  ln_dist_popcenter  	
		
	
	global 		era5 v01_rf4 v02_rf4 v03_rf4 v04_rf4 v05_rf4 v06_rf4 v07_rf4 v08_rf4 v09_rf4 v10_rf4 v11_rf4 v12_rf4 v13_rf4 v14_rf4
	
	global  	chirps v01_rf2 v02_rf2 v03_rf2 v04_rf2 v05_rf2 v06_rf2 v07_rf2 v08_rf2 v09_rf2 v10_rf2 v11_rf2 v12_rf2 v13_rf2 v14_rf2
	
	global 		cpc v01_rf3 v02_rf3 v03_rf3 v04_rf3 v05_rf3 v06_rf3 v07_rf3 v08_rf3 v09_rf3 v10_rf3 v11_rf3 v12_rf3 v13_rf3 v14_rf3

	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (crop == `crop_code') 
	}

	
	
* loop lasso different rf products 
	local 		products chirps cpc era5
	
	foreach 	product of local products {	
		* lasso linear reg to selec vars 
		lasso 		linear ln_yield_cp (d_* indc_* c.year dzone_* $inputs_cp $controls_cp /// 
					) $geo $`product', nolog rseed(9912) selection(plugin)
					
		lassocoef
		
		* these are all the variables
		global		selbaseline_`product' `e(allvars_sel)'
		
		* these are the variables chosen that were subject to selection by LASSO
		global 		testbaseline_`product' `e(othervars_sel)'
		
		*create a local to store globals 
		local 		current_selbaseline = "selbaseline_`product'"
		
		*reg 		ln_yield_cp $`current_selbaseline', vce(cluster cluster_id)
		svy: 		reg ln_yield_cp $`current_selbaseline'
	
		local 		lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
		local 		ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
		di 			"`lb', `ub',"
	}
	
	
	* check which rf variables are chosen 
	display 	"$testbaseline_chirps"
	display 	"$testbaseline_cpc"
	display 	"$testbaseline_era5"

* estimate model 2
	*erase 		"$export1/tables/model2/yield.tex"
	*erase 		"$export1/tables/model2/yield.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	


*	reg 		ln_yield_cp $selbaseline_chirps , vce(cluster ea_id_obs)
	svy: 		reg ln_yield_cp $selbaseline_chirps
	
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
**# e - model 3 - farm level
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
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat" 11 "Fruits" 12 "Cash Crops" , replace
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"


* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline_chirps"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id hh_id_obs ///
				ea_id_obs strataid pw aez  /// 
				(max) female_manager formal_education_manager hh_size /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey  intercropped  urban /// 
				ln_dist_popcenter ln_elevation farm_size nb_plots ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS nb_seasonal_crop /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(max) dzone_* hh_asset_index ag_asset_index /// 
				(first) v03_rf2 v10_rf2 ///
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
					
	/*
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	drop 		scalar temp_weight_test
	*/
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"
			
	svyset, 	clear
	*svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
	svyset 		ea_id_obs [pweight=pw], strata(strata) singleunit(centered)

	* no weights 
	*reg 		ln_yield_cp $selbaseline_chirps , vce(cluster cluster_id)
	
* run model 3
	*erase 		"$export1/tables/model3/yield.tex"
	*erase 		"$export1/tables/model3/yield.txt"
	

	svy: 		reg  ln_yield_cp $selbaseline_chirps 

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
	*keep 		wave country survey hh_id_obs
	
* save for merge 
	*save 		"$export1/dta_files_merge/hh_included.dta", replace
	

***********************************************************************
**# f - model 4 - hh FE 
***********************************************************************

* clear survey design settings 
	svyset,		clear 
	
* drop Mali bc hh and managers cannot be tracked 
	drop if 	country == "Mali"
	
	drop 		d_Mali
	
	svyset 		ea_id_obs [pweight=pw], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned hh_asset_index ag_asset_index /// 
				v03_rf2 v10_rf2 farm_size nb_plots crop aez) /// 
				vce(bootstrap)
				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(200) seed(123)

	global 		remove  d_Ethiopia d_Mali d_Malawi d_Niger d_Nigeria o.d_Tanzania
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 		selbaseline_4_5 : list global(selbaseline_chirps) - global(remove)
	display 	"$selbaseline_4_5"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	
*	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
				[pw = wgt_adj_surveypop],absorb(hh_id) // many reps fail due to collinearities in controls	
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
				[pw = pw],absorb(hh_id) // many reps fail due to collinearities in controls
				
	* no weights 
	*reghdfe 	ln_yield_cp $selbaseline_4_5 , absorb(hh_id) vce(cluster cluster_id)
	estimates 	store D

*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model4/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append

	*svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
	
	
	*areg 		ln_yield_cp $selbaseline_4_5 /// 
				[pw = wgt_adj_surveypop],absorb(hh_id_obs)
				

***********************************************************************
**# g - model 5 - plot-manager
***********************************************************************		

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	* drop if country == "Tanzania" & (wave == 1 | wave ==2 )
	
* merge hh 
	*merge m:1 	country wave hh_id_obs using "$export1/dta_files_merge/hh_included.dta"

	*keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	*drop 		_merge
	
* merge manager 
	*merge m:1 	country wave hh_id_obs manager_id_obs /// 
				using "$export1/dta_files_merge/manager_included.dta"
	
	*keep if 	_merge == 3 | country == "Mali"
	
	*drop 		_merge
	
* merge cluster 
	*merge m:1 	country wave lat_mod lon_modified /// 
				using "$export1/dta_files_merge/cluster_included.dta"
	
	*keep if 	_merge == 3 
	
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
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country hh_id_obs)
 	egen 		plot_manager_id = group(country manager_id_obs)
	egen 		plot_id = group(country plot_id_obs)
	egen 		parcel_id = group(country parcel_id_obs)
	egen 		cluster_id = group(lat_mod lon_modified)
	
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	gen			ln_elevation = asinh(elevation)
	
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
	
* create manager count by hh 
	bysort 		country hh_id wave manager_id_obs: gen flag = _n == 1
	gen 		manager_unique = manager_id_obs if flag == 1
	bysort 		country hh_id wave: egen nb_manager = count(manager_unique)
	drop 		flag manager_unique
	
* adjust hh weight - number of managers
	gen 		pw_manager = pw / nb_manager
	
	
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
	display 	"$selbaseline_4_5"

* collapse the data to a plot manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id /// 
				manager_id_obs hh_id_obs aez pw_manager /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ln_elevation farm_size nb_plots  ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS nb_seasonal_crop /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(max) dzone_* hh_asset_index ag_asset_index /// 
				(first) v03_rf2 v10_rf2 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(plot_manager_id wave)
						
		
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
	
* drop mali since hh and managers cannot be tracked 
	drop if 	country == "Mali"
	*** 5,577 obs dropped
	
	drop 		d_Mali
	/*
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	*** 4,605 obs dropped 
	
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	*/


* survey design
	svyset 		ea_id_obs [pweight=pw_manager], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned hh_asset_index ag_asset_index /// 
				v03_rf2 v10_rf2 farm_size nb_plots crop aez) /// 
				vce(bootstrap)


* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(200) seed(123)

	*global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)

* estimate model 5
	*erase 		"$export1/tables/model5/yield.tex"
	*erase 		"$export1/tables/model5/yield.txt"
	
	*bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
			[pw = wgt_adj_surveypop],absorb(manager_id_obs) 
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
				[pw = pw_manager],absorb(manager_id_obs) 
	*local lb 	= _b[year] - invttail(e(df_r),0.025)*_se[year]
	*local ub 	= _b[year] + invttail(e(df_r),0.025)*_se[year]
				
				
	*reghdfe 	ln_yield_cp $selbaseline_4_5 , absorb(manager_id_obs) vce(cluster cluster_id)
	estimates 	store E
	*test 		$test
	*local 		F1 = r(F)
	*outreg2 	using "$export1/tables/model5/yield.tex",  /// 
				keep(c.year  $sel ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append

	*areg 		ln_yield_cp $selbaseline_4_5 /// 
				[pw = wgt_adj_surveypop],absorb(manager_id_obs)
				

	
* keep only observations included in the regression
	*keep if 	e(sample)
	*keep 		wave country survey hh_id_obs manager_id_obs
	
* save for merge 
	*save 		"$export1/dta_files_merge/manager_included.dta", replace
	
***********************************************************************
**# h - model 6 - cluster 
***********************************************************************	

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear
	*drop if country == "Tanzania" & (wave == 1 | wave ==2 )
	
	
* merge hh 
	*merge m:1 	country wave hh_id_obs using "$export1/dta_files_merge/hh_included.dta"

	*keep if 	_merge == 3
	* if we mute this merge and use full sample, lasso chooses same rf vars for each product
	
	*drop 		_merge
	
* merge manager 
	*merge m:1 	country wave hh_id_obs manager_id_obs /// 
				using "$export1/dta_files_merge/manager_included.dta"
	
	*keep if 	_merge == 3 | country == "Mali"
	
	*drop		_merge
	
* merge cluster 
	*merge m:1 	country wave lat_mod lon_modified /// 
				using "$export1/dta_files_merge/cluster_included.dta"
	
	*keep if 	_merge == 3 
	
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
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country hh_id_obs)
 	egen 		plot_manager_id = group(country manager_id_obs)
	egen 		plot_id = group(country plot_id_obs)
	egen 		parcel_id = group(country parcel_id_obs)
	egen 		cluster_id = group(lat_mod lon_modified)
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	gen 		ln_elevation = asinh(elevation)
	
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
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat" 11 "Fruits" 12 "Cash Crops", replace
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"


* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline_4_5"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id /// 
				ea_id_obs hh_id_obs aez /// 
				(max) female_manager formal_education_manager hh_size  /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ln_elevation farm_size nb_plots ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS nb_seasonal_crop /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(max) dzone_* hh_asset_index ag_asset_index  /// 
				(first) v03_rf2 v10_rf2 /// 
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
				8 "Sorghum" 9 "Tubers/Roots" 10 "Wheat" 11 "Fruits" 12 "Cash Crops", replace
	lab 		values crop crop
	lab var		crop "Main Crop group - cluster"

* creating missing value indicators at plot level
	foreach 	var of varlist yield_cp harvest_value_cp total_labor_days seed_value_cp /// 
				fert_value_cp plot_area_GPS {
					gen 	mi_`var' = 1 if `var' == .
				}
				
* to display lasso vars we can do this:
	display 	"$selbaseline_4_5"

* collapse the data to cluster level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop  ea_id_obs aez /// 
				(mean) female_manager formal_education_manager   /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped urban /// 
				ln_dist_popcenter ln_elevation  ///
				soil_fertility_index d_*  ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS nb_seasonal_crop dzone_* indc_* pw /// 
				(mean) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(sum) farm_size nb_plots ///
				(mean) age_manager year hh_size ///
				(mean) hh_asset_index ag_asset_index /// 
				(first) v03_rf2 v10_rf2 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(cluster_id wave)
						
* check if clusters cover multiple aez 
	gen 		aez_multiple = 0 
	foreach 	var of varlist dzone_* {
		replace 	aez_multiple = aez_multiple + (`var' > 0)
	}
	
	tab 		aez_multiple
	
* for crops and aez - choose the most representative category 
	
	foreach 	prefix in dzone_ indc_ {
   
		* capture all variable names starting with the prefix
		unab 	vars: `prefix'*
    
		* count the number of variables
		local 	num_vars = wordcount("`vars'")
    
		* create a variable to store the maximum value in each set
		egen 	maxval_`prefix' = rowmax(`vars')

    * create indicator variables for each category in each set
		forval 	i = 1/`num_vars' {
				* get the variable name in position i
				local 	varname = word("`vars'", `i')
        
				* create an indicator variable where the category has the maximum value
				gen 	`prefix'ind_`i' = (`varname' == maxval_`prefix') if maxval_`prefix' > 0
    }
    
		drop 	maxval_`prefix'
}				

* replace var 
	replace 	dzone_tropic_warm_arid = dzone_ind_1
	replace 	dzone_tropic_warm_semiarid = dzone_ind_2
	replace 	dzone_tropic_warm_subhumid = dzone_ind_3
	replace 	dzone_tropic_warm_humid = dzone_ind_4
	replace 	dzone_tropic_cool_arid = dzone_ind_5
	replace 	dzone_tropic_cool_semiarid = dzone_ind_6
	replace 	dzone_tropic_cool_subhumid = dzone_ind_7
	replace 	dzone_tropic_cool_humid = dzone_ind_8
	
	replace 	indc_Barley = indc_ind_1
	replace 	indc_Beans_Peas_Lentils_Peanuts = indc_ind_2
	replace 	indc_Maize = indc_ind_3
	replace 	indc_Millet = indc_ind_4
	replace 	indc_Nuts_Seeds = indc_ind_5
	replace 	indc_Other = indc_ind_6
	replace 	indc_Rice = indc_ind_7
	replace 	indc_Sorghum = indc_ind_8
	replace 	indc_Tubers_Roots = indc_ind_9
	replace 	indc_Wheat = indc_ind_10
	replace 	indc_Fruits = indc_ind_11
	replace 	indc_Cash_Crops = indc_ind_12
	
	drop 		dzone_ind_* indc_ind_*
	
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
	
	/*
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	* 631 observations dropped 
	
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	

	
	drop 		scalar temp_weight_test
	*/
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group - cluster"
				
* survey design
	svyset 		ea_id_obs [pweight=pw], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned hh_asset_index ag_asset_index /// 
				v03_rf2 v10_rf2 farm_size nb_plots  aez crop) ///
				vce(bootstrap)
				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(200) seed(123)


	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
*	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
				[pw = wgt_adj_surveypop],absorb(ea_id_obs) // many reps fail due to collinearities in controls

	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $selbaseline_4_5 /// 
				[pw = pw],absorb(ea_id_obs) // many reps fail due to collinearities in controls
	
	* no weights 
	*reg			ln_yield_cp $selbaseline_4_5 , vce(cluster cluster_id)

*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model6/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
				
	
	*areg 		ln_yield_cp $selbaseline_chirps /// 
				[pw = wgt_adj_surveypop],absorb(ea_id_obs)
				
	estimates 	store F
	
* keep only observations included in the regression
	*keep if 	e(sample)
	*keep 		wave country survey lat_mod lon_modified
	
* save for merge 
	*save 		"$export1/dta_files_merge/cluster_included.dta", replace
	
	
***********************************************************************
**# i - coefficient plot
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
				ylab(0.09 "9"  0.08 "8" 0.07 "7" 0.06 "6" 0.05 "5" 0.04 "4" /// 
				0.03 "3" 0.02 "2" /// 
				0.01 "1" 0 "0" -0.01 "-1" -0.02 "-2" /// 
				-0.03 "-3" -0.04 "-4" -0.05 "-5" -0.06 "-6", labsize(small) grid) /// 
				ytitle(Annual productivity change (%)) vertical xsize(5)
				
w

* save for image 
	graph 		export 	"$export1/figures/coefficients_plot.pdf", as(pdf) replace

			
