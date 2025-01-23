* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: jdm
* Edited on: 23 Jan 25
* Edited by:rg
* Stata v.18.0

* does
	* reads in and conducts replication of Wollburg et al.

* assumes
	* access to replication data
	
* TO DO:
	* include control variables in model 2
	
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
**# 1 - open replication data 
***********************************************************************

	use 		"$data/countries/aggregate/allrounds_final_year.dta", clear
	
***********************************************************************
**# 2 - run replication
***********************************************************************
	
* generate log yield
	gen				ln_yield1 = asinh(yield_kg1)
	gen 			ln_yield2 = asinh(yield_kg2)

* generate time trend
	sort			year
	egen			tindex = group(year)
	
*** NOTE DEFAULT FOR SVY IS ROBUST STANDARD ERRORS 	

***********************************************************************
**# 2 (a) - model 1 
***********************************************************************

***using yield variable generated
* estimate model 1 for yield 1
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield1 c.year if country=="`country'" 
	local lb = _b[c.year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[c.year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 using "$export1/tables/model1/yield1.tex",   keep(c.year) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

* estimate model 1 for yield 2
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield2 c.year if country=="`country'"
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 using "$export1/tables/model1/yield2.tex",   keep(c.year) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

*** trying to replicate table using yield value (yield_value_LCU)

* generate log yield value 
	gen 	ln_yield_value_LCU = asinh(yield_value_LCU)

* replicate model 1 results
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {

	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield_value_LCU c.year if country=="`country'" 
	local lb = _b[c.year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[c.year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 using "$export1/tables/model1/yield_value_LCU.tex",   keep(c.year) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

***********************************************************************
**# 2 (b) - model 2
***********************************************************************

* generate log variables for inputs and controls 
	gen 	ln_total_labor_days1 = asinh(total_labor_days1)
	gen 	ln_total_labor_days2 = asinh(total_labor_days2)
	
	gen 	ln_seed_kg1 = asinh(seed_kg1)
	gen 	ln_seed_kg2 = asinh(seed_kg2)
	
	gen 	ln_nitrogen_kg1 = asinh(nitrogen_kg1)
	gen 	ln_nitrogen_kg2 = asinh(nitrogen_kg2)
	
* define input and control globals 
	global 		inputs_cp1 ln_total_labor_days1 ln_seed_kg1 ln_nitrogen_kg1 
	
	global 		inputs_cp2 ln_total_labor_days2 ln_seed_kg2 ln_nitrogen_kg2 
	
	global 		controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock livestock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned harv_missing
	*** in this global they used miss_harvest_value_cp

* estimate model 2 for yield 1
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield1 c.year $inputs_cp1 $controls_cp if country=="`country'" 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 using "$export1/tables/model2/yield1.tex",   keep(c.year  $inputs_cp1 $controls_cp ) ctitle("`country'- model 2") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}


* estimate model 2 for yield 2 
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield2 c.year $inputs_cp2 $controls_cp if country=="`country'" 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	outreg2 using "$export1/tables/model2/yield2.tex",   keep(c.year  $inputs_cp2 $controls_cp ) ctitle("`country'- model 2") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

***********************************************************************
**# 3 (b) - model 3
***********************************************************************

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
	


	


