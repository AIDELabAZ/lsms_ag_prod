do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0a. Weight adjustments - constant price.do" 

use "${Clean}/Final/LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}/weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

** 1)
svy: reg ln_harvest_value_cp year i.Country 
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  replace
local r2 = e(r2_a)
di "`lb', `ub', `r2'"
estimates store A



** 2)
* lasso plugin
lasso linear ln_harvest_value_cp ($FE c.year $inputs_cp $controls_cp ) $geo $weather_all , nolog rseed(8788) selection(plugin) 
lassocoef 
global selbaseline `e(allvars_sel)'
global testbaseline `e(othervars_sel)'

svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline 
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
di "`lb', `ub',"
estimates store B
test $testbaseline
local F1 = r(F) 
test $inputs_cp
global F2 = r(F)
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append


** 3)

foreach var in harvest_value    total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   seed_value seed_kg inorganic_fertilizer_value     harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con     {
		replace `var'=`var'*plot_area
}

// main crops
bys hh_id wave main_crop: egen value_maincrop = total(harvest_value)
bys hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop


drop miss_*
	foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen mi_`var'=1 if `var'==. 
	}

collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1* admin_2* admin_3* admin_4* cluster_id main_crop       /// 
		 (max) agro_ecological_zone urban female_manager    formal_education_manager hh_size   hh_electricity_access  livestock  hh_shock ag_asset_index   total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market ln_dist_popcenter ln_dist_road ln_elevation ///
		 (max)      soil_fertility_index   ///
			(sum) harvest_value    harvest_transport_cost    /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    ///
			(max) strataid intercropped     ///
			(sum) total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) plot_area  ///
			(sum) seed_value seed_kg  ///
			(sum) inorganic_fertilizer_value    ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max)  used_pesticides   ///
		    (max) crop_shock   ///
			(max) plot_owned  irrigated     self_reported_area  ///
			(mean) age_manager    ///
			(first) tot_precip_sd_season tot_precip_min_season tot_precip_max_season temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_cumul_season tot_precip_below5p_season tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H  ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value    n_seed_value=seed_value n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost n_inorganic_fertilizer_value=inorganic_fertilizer_value   n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con , by(hh_id wave)
			
	foreach var of varlist harvest_value harvest_transport_cost seed_value seed_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con  {
		replace `var'=. if n_`var'==0
		drop n_`var'
	} 
	
		foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}
	

 foreach var in harvest_value   seed_value seed_kg inorganic_fertilizer_value   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		replace `var'=`var'/plot_area
		} 
	 	
	
	foreach var in harvest_value   seed_value seed_kg inorganic_fertilizer_value     total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen ln_`var'=ln(`var' +1)
		lab var ln_`var' "Natural log of `var'"
		}


		
// crop mix

	
	gen ln_plot_area = ln(plot_area)
	
	gen total_labor_days_nonhired = total_labor_days -  total_hired_labor_days
	gen year =  year(dofm(month_endseason_calendar))
	encode country, gen(Country)
	tabulate Country, generate(country_dummy) 
	encode main_crop, gen(Main_crop)
	gen ln_labor_days_nonhired = ln(total_labor_days_nonhired + 1)
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 


// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test


svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp  1.Country 1.Main_crop $selbaseline
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
estimates store C

global remove   311bn.agro_ecological_zone 314bn.agro_ecological_zone 
global test : list global(testbaseline) - global(remove)
test $test
local F1 = r(F)
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append


** 4)


svyset, clear
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) bsrweight(ln_harvest_value_cp year ln_plot_area ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation tot_precip_sd_season cluster_id  Country Main_crop agro_ecological_zone temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season) vce(bootstrap)

svydes ln_harvest_value_cp , single  generate(d)
bys strataid (ea):  gen ID = sum(ea != ea[_n-1])
bys strataid: egen count_ea = max(ID)
drop if count_ea<2 // drop singletons 
bsweights bsw, n(-1) reps(500) seed(123)

global remove  2.Country 3.Country 4.Country 5.Country 6.Country 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
global sel : list global(selbaseline) - global(remove)

bs4rw, rw(bsw*)  : areg ln_harvest_value_cp 1.Main_crop $sel [pw = wgt_adj_surveypop] , absorb(hh_id) // many reps fail due to collinearities in controls
estimates store D

test $test
local F1 = r(F)
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls - FE")  addtext(Main crop FE, YES, Country FE, YES)  append



** 5)

use "${Clean}/Final/LSMS_mega_panel_ARCHIVE090822.dta", clear


foreach var in harvest_value    total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   seed_value seed_kg inorganic_fertilizer_value     harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con     {
		replace `var'=`var'*plot_area
}

// main crops
bys plot_manager_id wave main_crop: egen value_maincrop = total(harvest_value)
bys plot_manager_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop


drop miss_*
	foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen mi_`var'=1 if `var'==. 
	}

collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1* admin_2* admin_3* admin_4* cluster_id main_crop       /// 
		 (max) agro_ecological_zone urban female_manager    formal_education_manager hh_size   hh_electricity_access  livestock  hh_shock ag_asset_index   total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market ln_dist_popcenter ln_dist_road ln_elevation ///
		 (max)      soil_fertility_index   ///
			(sum) harvest_value    harvest_transport_cost    /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    ///
			(max) strataid intercropped     ///
			(sum) total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) plot_area  ///
			(sum) seed_value seed_kg  ///
			(sum) inorganic_fertilizer_value    ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max)  used_pesticides   ///
		    (max) crop_shock   ///
			(max) plot_owned  irrigated     self_reported_area  ///
			(mean) age_manager    ///
			(first) tot_precip_sd_season tot_precip_min_season tot_precip_max_season temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_cumul_season tot_precip_below5p_season tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H  ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value    n_seed_value=seed_value n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost n_inorganic_fertilizer_value=inorganic_fertilizer_value   n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con , by(plot_manager_id wave)
			
	foreach var of varlist harvest_value harvest_transport_cost seed_value seed_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con  {
		replace `var'=. if n_`var'==0
		drop n_`var'
	} 
	
		foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}
	

 foreach var in harvest_value   seed_value seed_kg inorganic_fertilizer_value   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		replace `var'=`var'/plot_area
		} 
	 	
	
	foreach var in harvest_value   seed_value seed_kg inorganic_fertilizer_value     total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
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
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 


// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test


svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) bsrweight(ln_harvest_value_cp year ln_plot_area ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation tot_precip_sd_season cluster_id  Country Main_crop agro_ecological_zone temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season) vce(bootstrap)

svydes ln_harvest_value_cp , single  generate(d)
bys strataid (ea):  gen ID = sum(ea != ea[_n-1])
bys strataid: egen count_ea = max(ID)
drop if count_ea<2 // drop singletons + strata with very few EAs
preserve
bsweights bsw, n(-1) reps(500) seed(123)

global remove  2.Country 3.Country 4.Country 5.Country 6.Country 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
global sel : list global(selbaseline) - global(remove)

bs4rw, rw(bsw*): areg ln_harvest_value_cp 1.Main_crop $sel [pw = wgt_adj_surveypop] , absorb(plot_manager_id) 
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
estimates store E

test $test
local F1 = r(F)
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls - FE")  addtext(Main crop FE, YES, Country FE, YES)  append

** 6) 

use "${Clean}/Final/LSMS_mega_panel_ARCHIVE090822.dta", clear


foreach var in harvest_value    total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   seed_value seed_kg inorganic_fertilizer_value     harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con     {
		replace `var'=`var'*plot_area
}

// main crops
bys hh_id wave main_crop: egen value_maincrop = total(harvest_value)
bys hh_id wave (value_maincrop): gen main_crop2 = main_crop[_N]
drop main_crop 
rename main_crop2 main_crop


drop miss_*
	foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen mi_`var'=1 if `var'==. 
	}

collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1* admin_2* admin_3* admin_4* cluster_id main_crop       /// 
		 (max) agro_ecological_zone urban female_manager    formal_education_manager hh_size   hh_electricity_access  livestock  hh_shock ag_asset_index   total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market ln_dist_popcenter ln_dist_road ln_elevation ///
		 (max)      soil_fertility_index   ///
			(sum) harvest_value    harvest_transport_cost    /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    ///
			(max) strataid intercropped     ///
			(sum) total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) plot_area  ///
			(sum) seed_value seed_kg  ///
			(sum) inorganic_fertilizer_value    ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max)  used_pesticides   ///
		    (max) crop_shock   ///
			(max) plot_owned  irrigated     self_reported_area  ///
			(mean) age_manager    ///
			(first) tot_precip_sd_season tot_precip_min_season tot_precip_max_season temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_cumul_season tot_precip_below5p_season tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H  ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value    n_seed_value=seed_value n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost n_inorganic_fertilizer_value=inorganic_fertilizer_value   n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con , by(hh_id wave)
			
	foreach var of varlist harvest_value harvest_transport_cost seed_value seed_kg   total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con  {
		replace `var'=. if n_`var'==0
		drop n_`var'
	} 
	
		foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
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
	foreach var of varlist harvest_value    harvest_transport_cost seed_value seed_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen mi_`var'=1 if `var'==. 
	}

drop if cluster_id==. 

collapse (first)  country survey month_startseason_calendar month_endseason_calendar admin_1* admin_2* admin_3* admin_4*  main_crop strataid   /// 
		 (max) agro_ecological_zone urban female_manager    formal_education_manager hh_size   hh_electricity_access  livestock  hh_shock ag_asset_index   total_wgt_survey  pw  lat_modified lon_modified  ea ln_dist_market ln_dist_popcenter ln_dist_road ln_elevation ///
		 (max)      soil_fertility_index   ///
			(sum) harvest_value    harvest_transport_cost    /// 
			(sum) harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    ///
			(max)  intercropped     ///
			(sum) total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value ///
			(sum) plot_area  ///
			(sum) seed_value seed_kg  ///
			(sum) inorganic_fertilizer_value    ///
			(max) inorganic_fertilizer organic_fertilizer  ///
			(max)  used_pesticides   ///
		    (max) crop_shock   ///
			(max) plot_owned  irrigated     self_reported_area  ///
			(mean) age_manager    ///
			(first) tot_precip_sd_season tot_precip_min_season tot_precip_max_season temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_cumul_season tot_precip_below5p_season tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H  ///
			(count) mi_* /// 
			(count) n_harvest_value = harvest_value    n_seed_value=seed_value n_seed_kg=seed_kg  n_harvest_transport_cost= harvest_transport_cost n_inorganic_fertilizer_value=inorganic_fertilizer_value   n_total_labor_days=total_labor_days n_total_family_labor_days=total_family_labor_days n_total_hired_labor_days=total_hired_labor_days n_hired_labor_value=hired_labor_value n_plot_area=plot_area n_harvest_value_cp = harvest_value_cp n_seed_value_cp = seed_value_cp n_hired_labor_value_constant = hired_labor_value_constant n_inorganic_fert_value_con = inorganic_fert_value_con , by(cluster_id wave)
			
	foreach var of varlist harvest_value  seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con  {
		replace `var'=. if n_`var'==0
		drop n_`var'
	}
	
	
*** We create variables flagging the existence of missing values within clusters
	foreach var of varlist harvest_value  seed_value seed_kg total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   plot_area harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
		gen miss_`var'=1 if mi_`var'>=1 | `var'==.
		replace miss_`var'=0 if mi_`var'==0 
		lab var miss_`var' "FLAG: Does `var' contain one or more missing obs at the sub-plot or plot level?"
		lab val miss_`var' miss_`var'
		drop mi_`var'
	}

*** we scale for effective inputs/outputs

 foreach var in harvest_value  seed_value seed_kg inorganic_fertilizer_value     total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value   harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con  {
		replace `var'=`var'/plot_area
		} 
	 

*** We add logs
	foreach var in harvest_value  seed_value seed_kg  total_labor_days total_family_labor_days total_hired_labor_days hired_labor_value    inorganic_fertilizer_value     harvest_value_cp seed_value_cp hired_labor_value_constant inorganic_fert_value_con    {
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
		
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 


// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svyset, clear
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) bsrweight(ln_harvest_value_cp year ln_plot_area ln_labor_days_nonhired ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con  ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access  urban plot_owned miss_harvest_value_cp ln_dist_road ln_dist_popcenter soil_fertility_index ln_elevation tot_precip_sd_season cluster_id  Country Main_crop agro_ecological_zone temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season) vce(bootstrap)

svydes ln_harvest_value_cp , single  generate(d)
bys strataid (ea):  gen ID = sum(ea != ea[_n-1])
bys strataid: egen count_ea = max(ID)
drop if count_ea<2 // drop singletons + strata with very few EAs
bsweights bsw, n(-1) reps(500) seed(123)


global remove  2.Country 3.Country 4.Country 5.Country 6.Country 311bn.agro_ecological_zone 314bn.agro_ecological_zone 
global sel : list global(selbaseline) - global(remove)

bs4rw, rw(bsw*): areg ln_harvest_value_cp 1.Main_crop $sel [pw = wgt_adj_surveypop] , absorb(cluster_id) 
estimates store F

test $test
local F1 = r(F)
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls - FE")  addtext(Main crop FE, YES, Country FE, YES)  append

** 7)


use "${Clean}/Final/LSMS_mega_panel_ARCHIVE090822.dta", clear

do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}/weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

global remove  ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con miss_harvest_value_cp
global sel : list global(selbaseline) - global(remove)
svy: reg ln_harvest_value ln_hired_labor_value ln_seed_value ln_inorganic_fertilizer_value miss_harvest_value 1.Country 1.Main_crop  $sel

local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
di "`lb', `ub',"
estimates store G
test $testbaseline
local F1 = r(F) 

outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and weather controls - current prices") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append


** Graph



set scheme s1color

coefplot (A, mcolor(navy) ciopts(color(navy) recast(rcap))) (B,  mcolor(navy) ciopts(color(navy) recast(rcap))) (C,  mcolor(navy) ciopts(color(navy) recast(rcap))) (D,  mcolor(navy) ciopts(color(navy) recast(rcap))) (E,  mcolor(navy) ciopts(color(navy) recast(rcap))) (F, xscale(r(.5 1.5)) mcolor(navy) ciopts(color(navy) recast(rcap))) (G, xscale(r(.5 1.5)) mcolor(navy) ciopts(color(navy) recast(rcap))) , keep(year) xlabel(0.625 "Model 1" 0.75 "Model 2" 0.875 "Model 3" 1 "Model 4" 1.125 "Model 5" 1.25 "Model 6" 1.375 "Model 7" , labsize(small)) ytitle(Productivity growth) yline(0, lcolor(black%50)) ylab( 0.02 "2" 0.01 "1" 0 "0" -0.01 "-1" -0.02 "-2" -0.03 "-3" -0.04 "-4" -0.05 "-5" -0.06 "-6" -0.07 "-7", labsize(small) grid ) ytitle(Annual productivity change (%)) vertical leg(off) ciopts(recast(rcap)) xline(0.6875 0.8125 0.9375 1.0625 1.1875 1.3125 , lcolor(black%60))  xsize(5.5)

graph export "${Paper1_results}\Graphs\Fig1.pdf", replace as(pdf) name("Graph")


** Country-level results

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)	
	
svy: reg ln_harvest_value_cp c.year if country=="`country'" 
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 1") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)	
	
lasso linear ln_harvest_value_cp ( $FE_withincountry $inputs_cp $controls_cp ) $geo $weather_all_nodummies if country=="`country'", nolog rseed(8788) selection(plugin) 
lassocoef 
global sel `e(allvars_sel)'
global test `e(othervars_sel)'
svy: reg ln_harvest_value_cp $sel if country=="`country'"
local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
local ub = _b[year] + invttail(e(df_r),0.025)*_se[year] 
outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 2") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}





