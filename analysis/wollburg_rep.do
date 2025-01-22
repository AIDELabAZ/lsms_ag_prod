* Project: LSMS_ag_prod
* Created on: 22 Jan 2025
* Created by: alj
* Edited on: 22 Jan 2025
* Edited by: alj
* Stata v.18.5

* does
	* "replication" of Wollburg et al.

* assumes
	* access to replication data
	
* TO DO:
	* NOTE DEFAULT FOR SVY IS ROBUST STANDARD ERRORS 	
	*** Rodrigo, I added your name in a few spots where you'll maybe want / need to do things 
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	
* open log	
	cap log 		close
*	log using 		"$logout", append
	*** i'm not getting this to work, but don't want to bother to fix it
	
***********************************************************************
**# 1 - open replication data 
***********************************************************************

	use 		"$data/countries\aggregate\allrounds_final_year.dta", clear
	
* generate log yield named for processes 
	gen				ln_yield1 = asinh(yield_kg1)
	gen 			ln_yield2 = asinh(yield_kg2)
	
*** Rodrigo:  
*** WILL NEED TO GENERATE OTHER VARIABLES IN LOG	
*** ADD GLOBALS FOR CALLING $INPUTS $CONTROLS 
****** can do this here or could call different file / do in our cleaning files - up to you 	
	
***********************************************************************
**# 2 - run replication for process 1 
***********************************************************************
	
svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)
	
	
* MODEL 1

	svy: reg ln_yield1 year i.country 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("Geovariables and 	weather controls") addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  replace
	local r2 = e(r2_a)
	di "`lb', `ub', `r2'"
	estimates store A

* MODEL 2
	
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

***********************************************************************
**# 3 - run replication for process 2
***********************************************************************
	
	

***********************************************************************
**# 4 - COUNTRY LEVEL MODELS
***********************************************************************
		
	
/*	

*** COUNTRY LEVEL MODELS 
		
* estimate model 1 for yield 1
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield1 c.year if country=="`country'" 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

* estimate model 1 for yield 2
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield2 c.year if country=="`country'"
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

* estimate model 2 for yield 1
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield1 c.year if country=="`country'" 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

* estimate model 2 for yield 2 
	foreach country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
	
	svyset ea_id_obs [pweight=pw], strata(strataid) singleunit(centered)	
	
	svy: reg ln_yield1 c.year if country=="`country'" 
	local lb = _b[year] - invttail(e(df_r),0.025)*_se[year]
	local ub = _b[year] + invttail(e(df_r),0.025)*_se[year]
	*outreg2 using "${Paper1_temp}\FINAL.xls",   keep(c.year  $inputs_cp $controls_cp ) ctitle("`country'- model 1") 	addstat(  Upper bound CI, `ub', Lower bound CI, `lb') addtext(Main crop FE, YES, Country FE, YES)  append
}

*** RODRIGO: after c.year in the model 2 regressions, add the input variables and other control variables that we want to include