

**** Descriptive stats

** Fig - output descriptives


foreach var in harvest_value_cp total_harvest_val plot_area {
foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
gen total_harvest_val = harvest_value_cp * plot_area

	keep if country=="`country'"
	bys country survey wave hh_id  : egen nb_plot = count(plot_id)
	gen double temp_weight_surveypop = pw/nb_plot 
	bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
	gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
	bys country survey : egen temp_weight_test = sum(wgt_adj_surveypop) // TEST
	assert float(temp_weight_test)==float(total_wgt_survey) | total_wgt_survey==.
	drop scalar temp_weight_test
	
	svyset ea [pw=temp_weight_surveypop], strata(strata) singleunit(centered)	

	svy: mean `var' 
	mat list r(table)
	mat A = r(table)
	drop *
	svmat double A, name(coef)
	keep if _n==1 | _n==5 | _n==6
	gen variable = "`var'"
	gen country = "`country'"
	gen n = "b"
	replace n = "lb" in 2
	replace n = "ub" in 3
	keep country coef1 variable n
	save "$Temp/Analysis/Descriptive graph/descriptive_graph`country'`var'", replace

	}
}

use "$Temp/Analysis/Descriptive graph/descriptive_graphEthiopiaharvest_value_cp", clear
append using "$Temp/Analysis/Descriptive graph/descriptive_graphMalawiharvest_value_cp"
append using "$Temp/Analysis/Descriptive graph/descriptive_graphMaliharvest_value_cp"
append using "$Temp/Analysis/Descriptive graph/descriptive_graphNigerharvest_value_cp"
append using "$Temp/Analysis/Descriptive graph/descriptive_graphNigeriaharvest_value_cp"
append using "$Temp/Analysis/Descriptive graph/descriptive_graphTanzaniaharvest_value_cp"

foreach var in total_harvest_val plot_area {
foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
append using "$Temp/Analysis/Descriptive graph/descriptive_graph`country'`var'"
}
}

encode n, gen(x)
drop n
reshape wide coef1, i(variable country) j(x) 
rename (coef11 coef12 coef13) (mean lb ub)
encode country, gen(Country) 
lab def Countrylab 1 "ETH" 2 "MWI" 3 "MLI" 4 "NER" 5 "NGA" 6 "TZA"
lab val Country Countrylab
replace var = "Harvest, in constant $ per ha" if var=="harvest_value_cp"
replace var = "Total harvest value, in constant $" if var=="total_harvest_val"
replace var = "Plot area, in ha" if var=="plot_area"

	twoway (scatter  Country mean if var=="Harvest, in constant $ per ha",  msize(large) msymbol(o) mcolor(gs3) ) (rcap lb ub Country if var=="Harvest, in constant $ per ha", horizontal msize(huge) lcolor(gs6)), name(g21, replace) title({bf:A}, size(medium) position(11)) xtitle("Yield (constant USD/ha)", size(large) margin(t=3)) ylabel(1(1)6, valuelabel angle(0) labsize(medium) nogrid) yscale(r(0.75 6.25)) yline( 1.5 2.5 3.5 4.5 5.5, lcolor(black))  ytitle("") xline(0(500)4000, lcolor(gs12%30) ) xscale(r(0 4000)) xlab(, labsize(medium)) legend(order(1 "Mean" 2 "95% Confidence interval") rows(1) size(vsmall) symxsize(7) symysize(3)) graphregion(margin(l=0))
	
	twoway (scatter   Country mean if var=="Total harvest value, in constant $",  msize(large) msymbol(o) mcolor(gs3) ) (rcap lb ub Country if var=="Total harvest value, in constant $", horizontal msize(huge) lcolor(gs)), name(g22, replace)  title({bf:B}, size(medium) position(11)) xtitle("Harvest value (constant USD)", size(large) margin(t=3) ) ylabel(1(1)6, nolab notick angle(0) labsize(medium) nogrid) yscale(r(0.75 6.25)) yline( 1.5 2.5 3.5 4.5 5.5, lcolor(black)  )  ytitle("") xline(0(100)800, lcolor(gs12%30) )  xlab(, labsize(medium))  legend(off)
	
	twoway (scatter   Country mean if var=="Plot area, in ha",  msize(large) msymbol(o) mcolor(gs3) ) (rcap lb ub Country if var=="Plot area, in ha", horizontal msize(huge) lcolor(gs)), name(g23, replace)  title({bf:C}, size(medium) position(11)) xtitle("Plot area (ha)", size(large) margin(t=3)) ylabel(1(1)6, nolab notick angle(0) labsize(medium) nogrid) yscale(r(0.75 6.25)) yline( 1.5 2.5 3.5 4.5 5.5, lcolor(black)  )  ytitle("") xline(0(1)5, lcolor(gs12%30) )  xscale(r(0 5)) xlab(0(1)5, labsize(medium))  legend(off)

set scheme s1mono
grc1leg g21 g22 g23, rows(1) legendfrom(g21)   iscale(0.55) 


*** TABLE
/*
use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
foreach var of varlist harvest_value_cp plot_area seed_value_cp labor_days_nonhired  hh_size age_manager irrigated intercropped crop_shock  dist_popcenter soil_fertility_index elevation pii_season wet_spell_season tot_precip_cumul_season temperature_mean_season {
	use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
	bys country survey wave hh_id  : egen nb_plot = count(plot_id)
	gen double temp_weight_surveypop = pw/nb_plot 
	bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
	gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
	bys country survey : egen float temp_weight_test = sum(wgt_adj_surveypop) // TEST
	assert float(temp_weight_test)==float(total_wgt_survey) | total_wgt_survey==.
	drop scalar temp_weight_test
	svyset ea [pw=temp_weight_surveypop], strata(strata) singleunit(centered)	
	encode survey, gen(Survey)
	preserve
	svy: mean `var', over(Survey)
	
	mat list r(table)
	mat A = r(table)
	drop *
	svmat double A, name(coef)
	keep if _n==1 | _n==2
	gen n = "mean"
	replace n = "sd" in 2
	reshape long coef, i(n) j(numb)
	recode numb (1 2 = 1 "Mali") (3 4 = 2 "Niger") (5 6 7 8 = 3 "Ethiopia") (9 10 11 12 = 4 "Nigeria") (13 14 15 16 = 5 "Malawi") (17 18 19 20 21 = 6 "Tanzania"), gen(country)
	gen one =1
	bys n country (numb): gen wave = sum(one)
	drop one numb 
	rename coef `var'
	reshape wide `var', i(country wave) j(n) string
	
	save "${Paper1_temp}\Temp_`var'_descriptives.dta", replace 
	
	restore
	bysort Survey: egen med_`var' = median(`var')
	if inlist(`var', harvest_value_cp, plot_area, seed_value_cp, labor_days_nonhired ) {
	epctile `var', svy percentile(50) over(Survey)
	mat list r(table)
	mat A = r(table)
	drop *
	svmat double A, name(coef)
	keep if _n==1
	gen n = "median"
	reshape long coef, i(n) j(numb)
	recode numb (1 2 = 1 "Mali") (3 4 = 2 "Niger") (5 6 7 8 = 3 "Ethiopia") (9 10 11 12 = 4 "Nigeria") (13 14 15 16 = 5 "Malawi") (17 18 19 20 21 = 6 "Tanzania"), gen(country)
	gen one =1
	bys n country (numb): gen wave = sum(one)
	drop one numb 
	rename coef `var'
	reshape wide `var', i(country wave) j(n) string
	save "${Paper1_temp}\Temp_`var'_median.dta", replace 
	}
}
use "${Paper1_temp}\Temp_harvest_value_cp_median.dta", clear
merge 1:1 country wave using  "${Paper1_temp}\Temp_harvest_value_cp_descriptives.dta", nogen
foreach var in  plot_area seed_value_cp labor_days_nonhired inorganic_fert_value_con hh_size age_manager irrigated  crop_shock  dist_popcenter  elevation  wet_spell_season  temperature_mean_season  {
	if inlist("`var'", "plot_area", "seed_value_cp", "total_labor_days_nonhired" ) {
	merge 1:1 country wave using "${Paper1_temp}\Temp_`var'_median.dta", nogen
    }
merge 1:1 country wave using "${Paper1_temp}\Temp_`var'_descriptives.dta", nogen

}
*/

 
*** Missing vars 

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear

mdesc   ln_seed_value_cp ln_inorganic_fert_value_con  ln_hired_labor_value_constant ln_labor_days_nonhired  ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock formal_education_manager female_manager age_manager plot_owned miss_harvest_value_cp hh_shock livestock hh_size  hh_electricity_access urban agro_ecological_zone ln_dist_road ln_dist_popcenter ln_elevation soil_fertility_index    temperature_mean_season temperature_sd_season  temperature_min_season temperature_max_season temperature_LRmean_season     temperature_below15C_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_maxmax_season temperature_maxmin_season temperature_minmax_season temperature_minmin_season temperature_maxrange_season   tot_precip_sd_season tot_precip_min_season tot_precip_max_season      tot_precip_cumul_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_below1p_season tot_precip_below5p_season  tot_precip_0precip_season   tot_precip_LRmean_season   precipitation_maxmax_season max_5day_precip_season pii_season days_above_10mm_season days_above_20mm_season dry_spell_season wet_spell_season 


** Robustness checks

* Omitted countries & crop types

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline  , 
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("model 2")   replace

foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

drop if country=="`country'"
	
merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", keep(master match) nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline  , 
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("model 2 - without `country'")  addtext(Main crop FE, YES, Country FE, YES)  append

}


use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 


merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", keep(master match) nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline  , 

foreach x in 1 2 3 4 5  7 8 9 10 {
	
use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do" 

drop if contains_crop_`x'==1
	
// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline  , 
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("model 2 - without crop `x'")  addtext(Main crop FE, YES, Country FE, YES)  append
}

** Alternative pty measures

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do"

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen 
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

global remove ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con
global sel : list global(selbaseline) - global(remove)
svy: reg ln_harvest_value_perld_cp 1.Country 1.Main_crop ln_total_labor_days_tot ln_seed_value_perld_cp ln_hired_labor_value_perld_cp ln_inorg_fert_value_perld_cp  $sel
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("PER LD")  addtext(Main crop FE, YES, Country FE, YES)  append
test $testbaseline

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do"

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen  
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
  
global remove ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con
global sel : list global(selbaseline) - global(remove)
svy: reg ln_harvest_value_perseed_cp 1.Country 1.Main_crop ln_labor_days_nonhired_perseed ln_seed_value_cp_tot ln_hired_labor_value_perseed_cp  ln_inorg_fert_value_perseed_cp $sel
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("PER SEED")  addtext(Main crop FE, YES, Country FE, YES)  append
test $testbaseline

** Outlier correction

**** Winsorised results

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do"

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
 
svy:reg ln_harvest_value_cp_95 1.Country 1.Main_crop $selbaseline
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("95 wins")  addtext(Main crop FE, YES, Country FE, YES)  append

preserve
svyset, clear
foreach var of varlist ln_harvest_value_cp {
winsor2 `var' if `var'>0 , cuts(1 99) trim 
}

drop wgt_adj_surveypop 
drop if ln_harvest_value_cp==. 

// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp_tr 1.Country 1.Main_crop $selbaseline
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("99 trim")  addtext(Main crop FE, YES, Country FE, YES)  append
restore

preserve
svyset, clear
foreach var of varlist ln_harvest_value_cp {
winsor2 `var' if `var'>0 , cuts(1 95) trim 
}

drop wgt_adj_surveypop 
drop if ln_harvest_value_cp==. 

// Weights summing to total population of combined strata
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)
drop scalar temp_weight_test

svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp_tr 1.Country 1.Main_crop $selbaseline 
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("95 trim")  addtext(Main crop FE, YES, Country FE, YES)  append
restore


svy: reg ln_harvest_value_cp_99_md 1.Country 1.Main_crop $selbaseline  
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("99 MR")  addtext(Main crop FE, YES, Country FE, YES)  append

svy: reg ln_harvest_value_cp_95_md 1.Country 1.Main_crop $selbaseline  
outreg2 using "${Paper1_temp}\FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("95 MR")  addtext(Main crop FE, YES, Country FE, YES)  append



* Missing values


// TEST - sensitivity of results to missing values (1)

use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
	
foreach var of varlist temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_sd_season tot_precip_cumul_season tot_precip_below5p_season  tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H {	
	gen `var'2 = c.`var'#c.`var'
}

bys country survey wave hh_id  : egen nb_plot = count(plot_id)
gen double temp_weight_surveypop = pw/nb_plot 
bys country survey : egen double sum_weight_wave_surveypop = sum(temp_weight_surveypop)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * temp_weight_surveypop 
bys country survey : egen float temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey) | total_wgt_survey==.
drop scalar temp_weight_test
drop nb_plot   temp_weight_surveypop sum_weight_wave_surveypop   


replace crop_shock = . if crop_shock==.a
gen constrain=1 if inlist(., ln_harvest_value_cp, year, ln_plot_area,ln_labor_days_nonhired, ln_seed_value_cp, ln_hired_labor_value_constant, ln_inorganic_fert_value_con, ag_asset_index, used_pesticides,organic_fertilizer,irrigated,intercropped,crop_shock,hh_shock,livestock,hh_size,formal_education_manager,female_manager,age_manager,hh_electricity_access,urban,plot_owned,miss_harvest_value_cp, ln_dist_road, ln_dist_popcenter, soil_fertility_index, ln_elevation, tot_precip_sd_season, cluster_id, Country, Main_crop, agro_ecological_zone, temperature_sd_season, temperature_min_season, temperature_max_season, temperature_mean_season, temperature_above25C_season, temperature_above30C_season, pw, strataid)

svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

svy: reg ln_harvest_value_cp c.year i.Country if constrain!=1, 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("All but FE")  replace
estimates store mis1


svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock formal_education_manager female_manager age_manager plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Household controls")  append
estimates store mis2

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Weather vars")  append
estimates store mis3

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovars")  append
estimates store mis4

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index  hh_shock livestock hh_size hh_electricity_access urban 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Plot controls")  append
estimates store mis5

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_seed_value_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Inputs (except seeds)")  append
estimates store mis6

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season if constrain!=1 , 
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("seeds")  append
estimates store mis7

*** 


svy: reg ln_harvest_value_cp c.year i.Country i.Main_crop  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("All but FE")  replace
estimates store mis11


svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock formal_education_manager female_manager age_manager plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Household controls")  append
estimates store mis12

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Weather vars")  append
estimates store mis13

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovars")  append
estimates store mis14

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_seed_value_cp ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index  hh_shock livestock hh_size hh_electricity_access urban 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Plot controls")  append
estimates store mis15

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_seed_value_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("Inputs (except seeds)")  append
estimates store mis16

svy: reg ln_harvest_value_cp year 1.Country 2.Country 3.Country 4.Country 5.Country 6.Country 1.Main_crop 2.Main_crop 3.Main_crop 4.Main_crop 5.Main_crop 6.Main_crop 7.Main_crop 8.Main_crop 9.Main_crop 10.Main_crop ln_plot_area ln_labor_days_nonhired ln_hired_labor_value_constant ln_inorganic_fert_value_con ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned miss_harvest_value_cp 311bn.agro_ecological_zone 314bn.agro_ecological_zone ln_dist_road soil_fertility_index ln_elevation temperature_meanmonth_lag4H  1bn.country_dummy1#c.temperature_above30C_season 1bn.country_dummy2#c.temperature_above30C_season 1bn.country_dummy3#c.temperature_above35C_season 0bn.country_dummy5#c.temperature_above35C_season 1bn.country_dummy6#c.tot_precip_below5p_season 1bn.country_dummy2#c.tot_precip_cumulmonthH 0bn.country_dummy4#c.tot_precip_cumulmonthH 1bn.country_dummy2#c.tot_precip_cumulmonth_lag1H 0bn.country_dummy6#c.tot_precip_cumulmonth_lag5H 0bn.country_dummy4#c.tot_precip_cumulmonth_lag6H 1bn.country_dummy1#c.temperature_above25C_season2 1bn.country_dummy2#c.temperature_above25C_season2 0bn.country_dummy1#c.temperature_above30C_season2 0bn.country_dummy2#c.tot_precip_below1p_season2 1bn.country_dummy4#c.tot_precip_lagP_cumul3months2 1bn.country_dummy2#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lead1P2 1bn.country_dummy3#c.tot_precip_cumulmonth_lag3H2 0bn.country_dummy5#c.tot_precip_cumulmonth_lag3H2 1bn.country_dummy4#c.tot_precip_cumulmonth_lag5H2 1bn.country_dummy2#c.dry_spell_season  
outreg2 using "${Paper1_temp}\TEST_missingval.xls",  keep(c.year  $inputs_cp $controls_cp ) ctitle("seeds")  append
estimates store mis17



import delim "${Paper1_temp}/TEST_missingval.txt", clear 
export excel "${Paper1_results}/TEST - missing val.xls", sheet("Constant sample", replace) 


import delim "${Paper1_temp}/TEST_missingval_fluc.txt", clear 
export excel "${Paper1_results}/TEST - missing val.xls", sheet("Fluctuating sample", replace) 

coefplot (mis1, mcolor(navy) ciopts(color(navy) recast(rcap))  label(Baseline sample) ) (mis11, mcolor(red) msymbol() ciopts(color(red) recast(rcap)) label(Including new observations)), ylab( 0.02 "2" 0 "0" -0.02 "-2" -0.04 "-4") bylabel(Model A)  legend(position(0)) || (mis2, mcolor(navy) ciopts(color(navy) recast(rcap))) (mis12, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model B)  legend(position(0)) || (mis3, mcolor(navy) ciopts(color(navy) recast(rcap)) ) (mis13, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model C)  legend(position(0)) || (mis4, mcolor(navy) ciopts(color(navy) recast(rcap))) (mis14, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model D)  legend(position(0)) || (mis5, mcolor(navy) ciopts(color(navy) recast(rcap))) (mis15, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model E)  legend(position(0)) || (mis6, mcolor(navy) ciopts(color(navy) recast(rcap))) (mis16, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model F)  legend(position(0))|| (mis7, mcolor(navy) ciopts(color(navy) recast(rcap))) (mis17, mcolor(red) ciopts(color(red) recast(rcap))), bylabel(Model G)  keep(year) xlabel(, labsize(small)) ytitle(Productivity growth) yline(0, lcolor(black%50)) ylab(, labsize(small) grid ) xscale(lstyle(none)) ytitle(Annual productivity change (%)) xlab(none) vertical leg(off) ciopts(recast(rcap))   xsize(5.5)  legend(position(0))

// Imputed missing values 
use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear
do "${Do}/1. Analysis/Paper 1/SCIENCE - analysis/Manuscript/Prep/0b. Pre-Analysis - constant price.do"

merge 1:1 country survey wave month_endseason_calendar hh_id plot_id using "${Paper1_temp}\weights_adj1_cp_ARCHIVE.dta", nogen
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)
svy: reg ln_harvest_value_cp 1.Country 1.Main_crop $selbaseline , 
outreg2 using "${Paper1_temp}/FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Imputed - baseline")  addtext(Main crop FE, YES, Country FE, YES)  append


use "${Clean}\Final\LSMS_mega_panel_ARCHIVE090822.dta", clear

global missing_dummies


foreach var of varlist temperature_sd_season temperature_min_season temperature_max_season temperature_mean_season temperature_above25C_season temperature_above30C_season temperature_above35C_season temperature_below15C_season temperature_LRmean_season temperature_lagP_av3months temperature_lagP_av6months temperature_meanmonth_lag1P temperature_meanmonth_lag2P temperature_meanmonth_lag3P temperature_meanmonth_lead1P temperature_meanmonth_lead2P temperature_meanmonth_lead3P temp_meanmonthH temperature_meanmonthP tot_precip_sd_season tot_precip_cumul_season tot_precip_below5p_season  tot_precip_below1p_season tot_precip_0precip_season tot_precip_above95p_season tot_precip_above99p_season tot_precip_LRmean_season tot_precip_lagP_cumul3months tot_precip_lagP_cumul6months tot_precip_cumulmonth_lag1P tot_precip_cumulmonth_lag2P tot_precip_cumulmonth_lag3P tot_precip_cumulmonth_lead1P tot_precip_cumulmonth_lead2P tot_precip_cumulmonth_lead3P tot_precip_cumulmonthH tot_precip_cumulmonthP temperature_meanmonth_lag1H temperature_meanmonth_lag2H temperature_meanmonth_lag3H temperature_meanmonth_lag4H temperature_meanmonth_lag5H temperature_meanmonth_lag6H tot_precip_cumulmonth_lag1H tot_precip_cumulmonth_lag2H tot_precip_cumulmonth_lag3H tot_precip_cumulmonth_lag4H tot_precip_cumulmonth_lag5H tot_precip_cumulmonth_lag6H {	
	gen `var'2 = c.`var'#c.`var'
}



set seed 1234

drop if pw==.
bys country survey : egen double sum_weight_wave_surveypop = sum(pw)
gen double scalar =  total_wgt_survey / sum_weight_wave_surveypop
gen double wgt_adj_surveypop = scalar * pw 
bys country survey : egen double temp_weight_test = sum(wgt_adj_surveypop) // TEST
assert float(temp_weight_test)==float(total_wgt_survey)			
svyset ea [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

gen constrain=1 if inlist(., ln_harvest_value_cp, year, ln_plot_area,ln_labor_days_nonhired, ln_seed_value_cp, ln_hired_labor_value_constant, ln_inorganic_fert_value_con, ag_asset_index, used_pesticides,organic_fertilizer,irrigated,intercropped,crop_shock,hh_shock,livestock,hh_size,formal_education_manager,female_manager,age_manager,hh_electricity_access,urban,plot_owned,miss_harvest_value_cp, ln_dist_road, ln_dist_popcenter, soil_fertility_index, ln_elevation, tot_precip_sd_season, cluster_id, Country, Main_crop, agro_ecological_zone, temperature_sd_season, temperature_min_season, temperature_max_season, temperature_mean_season, temperature_above25C_season, temperature_above30C_season, pw, strataid)
replace constrain = 0 if constrain==.

foreach var in ln_harvest_value_cp  ln_plot_area  ln_seed_value_cp ln_inorganic_fert_value_con  ln_hired_labor_value_constant ln_labor_days_nonhired  ag_asset_index used_pesticides organic_fertilizer irrigated intercropped crop_shock formal_education_manager female_manager age_manager plot_owned miss_harvest_value_cp hh_shock livestock hh_size  hh_electricity_access urban  {
	set seed 1234
	replace `var' = -9 if `var' == . 

}


svy: reg ln_harvest_value_cp 1.Country 1.Main_crop  $selbaseline constrain
outreg2 using "${Paper1_temp}/FINAL_RC.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Imputed ")  addtext(Main crop FE, YES, Country FE, YES)  append
estimates store Imputed
//coefplot (Baseline, mcolor(navy) ciopts(color(navy) recast(rcap))) (Imputed,  mcolor(red) ciopts(color(red) recast(rcap))), keep(year) vertical title(Test number 2) ylabel(, grid)

// counts


