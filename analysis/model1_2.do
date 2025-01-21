* Project: LSMS_ag_prod
* Created on: Oct 2024
* Created by: jdm
* Edited on: 21 Jan 24
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
