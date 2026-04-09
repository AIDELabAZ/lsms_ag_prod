*** BEGIN *** 

* Project: LSMS_ag_prod 
* Created on: 30 march 2026
* Created by: alj
* Edited on: 9 april 2026
* Edited by: alj
* Stata v.19.0

* does
	* reads in and conducts replication of Wollburg et al.
	* it uses full sample, not tight sample
	* drop Mali before running models 4 and 5 since hh and plots /// 
	cannot be tracked over time.

* assumes
	* access to replication data
	
* notes:
	* run time is on the scale of hours - (if reps > 4000) ...  
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global mergeit 	"$output/merged_data"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	global export1 	"$output/graphs&tables"
	global decomp   "$export1/dta_files_merge/decomp_hh_early_late_BALANCED.dta"
	
* open log	
	cap log 		close
	
***********************************************************************
**# 1 - generate  hh_id, plot_manager_id, and cluster_id, main crop
**********************************************************************

* open dataset
	*use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear
	
	merge m:m lat_modified lon_modified using "$mergeit/labor.dta"
	
* these labor values haven't really been dealt with - going to winsorize 
	
	cap 		which winsor2
	if 			_rc ssc install winsor2

* winsorized copies
	foreach 	v in total_labor_days total_family_labor_days total_hired_labor_days {
    gen 		`v'_w = `v'
		}

* within country
	levelsof 	country, local(ctrys)
	foreach 	c of local ctrys {
    foreach 	v in total_labor_days total_family_labor_days total_hired_labor_days {
        quietly winsor2 `v'_w if country == "`c'", cuts(1 99) replace
		}
	}

* make winsorized labor/ha 
	replace 	plot_area_GPS = . if plot_area_GPS <= 0

	gen 		labor_tot_ha_w = total_labor_days_w / plot_area_GPS
	gen 		labor_fam_ha_w = total_family_labor_days_w / plot_area_GPS
	gen 		labor_hir_ha_w = total_hired_labor_days_w  / plot_area_GPS

* transform 
	gen 		labor_tot_ha_asinh = asinh(labor_tot_ha_w)
	gen 		labor_fam_ha_asinh = asinh(labor_fam_ha_w)
	gen 		labor_hir_ha_asinh = asinh(labor_hir_ha_w)

	sum 		labor_tot_ha_asinh labor_fam_ha_asinh labor_hir_ha_asinh

* then back to it ... 

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
	egen 		hh_id = group(country wave hh_id_obs)
	egen 		hh_panel = group (country hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
* create total_wgt_survey varianble 
	bysort 		country wave (pw): egen total_wgt_survey = total(pw)
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
	
***********************************************************************
**# 2 - model 1: plot-level
***********************************************************************

* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)

	
* generate dummies for each country 
	foreach 	country in Ethiopia Mali Malawi Niger Nigeria Tanzania {
		gen 	d_`country' = 1 if country == "`country'"
		replace	d_`country' = 0 if d_`country' == .
	}
	
* run survey-weighted regression 
	svyset 		ea_id_obs [pweight = wgt_adj_surveypop], strata(strataid) singleunit(centered)
	
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
**# 3 - model 2: plot-level
***********************************************************************

* generate log variables for inputs and controls 
	gen 		ln_total_labor_days = asinh(total_labor_days)
	gen 		ln_seed_value_cp = asinh(seed_value_cp)	
	gen 		ln_plot_area_GPS = asinh(plot_area_GPS)
	gen			ln_fert_value_cp = asinh(fert_value_cp)
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	*gen 		ln_elevation = asinh(elevation)

	
* define input and control globals 
	global 		inputs_cp ln_total_labor_days ln_seed_value_cp  ln_fert_value_cp ln_plot_area_GPS
	global 		controls_cp used_pesticides organic_fertilizer irrigated intercropped crop_shock hh_shock hh_size formal_education_manager female_manager age_manager hh_electricity_access urban plot_owned 
	*** in this global they used miss_harvest_value_cp
	
	global 		geo  ln_dist_popcenter soil_fertility_index   
	*** included but we do not have it yet: i.agro_ecological_zone, ln_dist_road, ln_elevation
	
	*global 		FE i.Country i.crop 
	*** instead of crop they use Main_crop
	
	* check 0b. pre-analysis do file- lines 60 to 70 to see how they defined next global
	
	global 		weather_all v01_rf1 v02_rf1 v03_rf1 v04_rf1 v05_rf1 v06_rf1 v07_rf1 v08_rf1 v09_rf1 v10_rf1 v11_rf1 v12_rf1 v13_rf1 v14_rf1
	*** mali only country with missing values (38,564 observations)
	
/*
	* Mali weather data is in v**_1_arc and v**_2_arc , trying to replace the missing values with real values 
	foreach 	i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 {
					replace v`i'_rf1 = v`i'_rf1_t1 if country == "Mali" & v`i'_rf1_t1 !=.
					replace v`i'_rf1 = v`i'_2_t1 if country == "Mali" & v`i'_2_arc !=.
	}
*/
	
* generate dummy for crops
	levelsof 	crop, local(crop_levels)  

	foreach 	crop_code in `crop_levels' {
		local 		crop_label : label crop `crop_code'
		local 		clean_label = subinstr("`crop_label'", "/", "_", .)  
		local 		clean_label = subinstr("`clean_label'", " ", "_", .) 
    
		gen 		indc_`clean_label' = (crop == `crop_code') 
	}


* lasso linear regression to select variables
	lasso		linear ln_yield_cp (d_* indc_* c.year $inputs_cp $controls_cp ) $geo $weather_all , nolog rseed(9912) selection(plugin) 
	*** variables in parentheses are always included
	*** vars out of parentheses are subject to selection by LASSO
	lassocoef
	
	global		selbaseline `e(allvars_sel)'
	*** these are all the variables
	
	global 		testbaseline `e(othervars_sel)'
	*** these are the variables chosen that were subject to selection by LASSO
	
* estimate model 2
	*erase 		"$export1/tables/model2/yield.tex"
	*erase 		"$export1/tables/model2/yield.txt"
	*** erase the files to avoid appending 6 columns every time we run the loop
	
	svy: 		reg ln_yield_cp $selbaseline 
	
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
**# 4 - DECOMPOSITION 
***********************************************************************
 * compare within vs between households

* define early/late period bins 
	capture 	drop period
	gen 		period = .
	replace 	period = 0 if inrange(year, 2008, 2011)
	replace 	period = 1 if inrange(year, 2018, 2021)
	drop if 	period == .

	label 		define period 0 "Early (2008-2011)" 1 "Late (2018-2021)", replace
	label 		values period period

* construct household-period area totals and within-household plot weights
	bysort 		hh_panel period: egen hh_area_pt = total(plot_area_GPS)
	gen 		w_plot_hh = plot_area_GPS / hh_area_pt

* hh-period outcome = area-weighted mean of plot outcome
	gen 		y_plot_w = w_plot_hh * ln_yield_cp
	bysort 		hh_panel period: egen y_hh_pt = total(y_plot_w)

* labor intensity measures 
* area-weight household-period labor intensity
	gen Ltot_plot_w = w_plot_hh * labor_tot_ha_asinh
	gen Lfam_plot_w = w_plot_hh * labor_fam_ha_asinh
	gen Lhir_plot_w = w_plot_hh * labor_hir_ha_asinh

	bysort hh_panel period: egen Ltot_hh_pt = total(Ltot_plot_w)
	bysort hh_panel period: egen Lfam_hh_pt = total(Lfam_plot_w)
	bysort hh_panel period: egen Lhir_hh_pt = total(Lhir_plot_w)

* collapse to ONE record per household-period
	preserve
	keep country hh_panel period wgt_adj_surveypop y_hh_pt ///
     Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt

* aggregate hh.
	collapse (mean) wgt_adj_surveypop ///
         (mean) y_hh_pt Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt, ///
         by(hh_panel country period)

* normalize
	bysort period: egen wsum = total(wgt_adj_surveypop)
	gen w_hh = wgt_adj_surveypop / wsum

* reshape to wide early/late 
	keep hh_panel country period w_hh y_hh_pt Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt
	reshape wide y_hh_pt Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt w_hh, i(hh_panel) j(period)
	
* need to balance ... 
	drop if missing(y_hh_pt0) | missing(y_hh_pt1)

*re-normalize 
	quietly summarize w_hh0
	scalar w0sum = r(sum)
	quietly summarize w_hh1
	scalar w1sum = r(sum)

	replace w_hh0 = w_hh0 / w0sum
	replace w_hh1 = w_hh1 / w1sum

* means?? 
	quietly summarize y_hh_pt0 [aw = w_hh0]
	scalar Y0 = r(mean)
	quietly summarize y_hh_pt1 [aw = w_hh1]
	scalar Y1 = r(mean)
	scalar dY = Y1 - Y0

	foreach v in Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt {
		quietly summarize `v'0 [aw = w_hh0]
		scalar `v'_0 = r(mean)
		quietly summarize `v'1 [aw = w_hh1]
		scalar `v'_1 = r(mean)
		scalar d_`v' = `v'_1 - `v'_0
	}

* within/between decomposition 
	gen wbar = (w_hh0 + w_hh1)/2
	gen ybar = (y_hh_pt0 + y_hh_pt1)/2	
	gen dy   = (y_hh_pt1 - y_hh_pt0)	
	gen dw   = (w_hh1 - w_hh0)

	gen within_y  = wbar * dy
	gen between_y = ybar * dw

	quietly summarize within_y
	scalar WITHIN_Y = r(sum)
	quietly summarize between_y
	scalar BETWEEN_Y = r(sum)

* and now labor
	foreach v in Ltot_hh_pt Lfam_hh_pt Lhir_hh_pt {
		gen `v'_bar = (`v'0 + `v'1)/2
		gen d_`v'_i = (`v'1 - `v'0)

		gen within_`v'  = wbar * d_`v'_i
		gen between_`v' = `v'_bar * dw

		quietly summarize within_`v'
		scalar WITHIN_`v' = r(sum)
		quietly summarize between_`v'
		scalar BETWEEN_`v' = r(sum)
	}

* PRINT PRINT PRINT 
*** redo format?? i don't like the "------------------------------------------------------------"

di "------------------------------------------------------------"
di "HH decomposition (Balanced households; Early vs Late)"
di "Outcome: ln_yield_cp"
di "Mean early  Y0: " %9.4f Y0
di "Mean late   Y1: " %9.4f Y1
di "Total dY       : " %9.4f dY
di "Within component: " %9.4f WITHIN_Y
di "Between component:" %9.4f BETWEEN_Y
di "Check (W+B)     : " %9.4f (WITHIN_Y + BETWEEN_Y)
di "------------------------------------------------------------"

di "Labor decomposition (asinh(winsor labor/ha); balanced sample):"

di "Total labor  early: " %9.4f Ltot_hh_pt_0 " late: " %9.4f Ltot_hh_pt_1 ///
   " d: " %9.4f (Ltot_hh_pt_1 - Ltot_hh_pt_0)
di "  within: " %9.4f WITHIN_Ltot_hh_pt " between: " %9.4f BETWEEN_Ltot_hh_pt ///
   " check: " %9.4f (WITHIN_Ltot_hh_pt + BETWEEN_Ltot_hh_pt)

di "Family labor early: " %9.4f Lfam_hh_pt_0 " late: " %9.4f Lfam_hh_pt_1 ///
   " d: " %9.4f (Lfam_hh_pt_1 - Lfam_hh_pt_0)
di "  within: " %9.4f WITHIN_Lfam_hh_pt " between: " %9.4f BETWEEN_Lfam_hh_pt ///
   " check: " %9.4f (WITHIN_Lfam_hh_pt + BETWEEN_Lfam_hh_pt)

di "Hired labor  early: " %9.4f Lhir_hh_pt_0 " late: " %9.4f Lhir_hh_pt_1 ///
   " d: " %9.4f (Lhir_hh_pt_1 - Lhir_hh_pt_0)
di "  within: " %9.4f WITHIN_Lhir_hh_pt " between: " %9.4f BETWEEN_Lhir_hh_pt ///
   " check: " %9.4f (WITHIN_Lhir_hh_pt + BETWEEN_Lhir_hh_pt)

di "------------------------------------------------------------"

* save 
	cap mkdir "$export1/dta_files_merge"
	
	save "$export1/dta_files_merge/decomp_hh_early_late_BALANCED.dta", replace
	
* export tables 

/*
	cap which esttab
	if _rc ssc install estout, replace
	
	use "$decomp", clear

* Helper: compute weighted means and midpoint decomposition for one outcome pair
cap program drop _one_decomp
program define _one_decomp, rclass
    version 18
    syntax varlist(min=2 max=2) , W0(name) W1(name)
    tokenize `varlist'
    local v0 `1'
    local v1 `2'

    tempvar w0n w1n wbar dvi vbar dwi within_i between_i

    * normalize weights within this sample for each period
    gen double `w0n' = `w0'
    gen double `w1n' = `w1'
    quietly summarize `w0n'
    replace `w0n' = `w0n' / r(sum)
    quietly summarize `w1n'
    replace `w1n' = `w1n' / r(sum)

    * weighted means
    gen double __tmp0 = `w0n' * `v0'
    gen double __tmp1 = `w1n' * `v1'
    quietly summarize __tmp0
    return scalar mean0 = r(sum)
    quietly summarize __tmp1
    return scalar mean1 = r(sum)
    return scalar d = return(mean1) - return(mean0)

    * midpoint (Shapley) within/between
    gen double `wbar' = 0.5*(`w0n' + `w1n')
    gen double `dvi'  = (`v1' - `v0')
    gen double `vbar' = 0.5*(`v0' + `v1')
    gen double `dwi'  = (`w1n' - `w0n')

    gen double `within_i'  = `wbar' * `dvi'
    gen double `between_i' = `vbar' * `dwi'

    quietly summarize `within_i'
    return scalar within = r(sum)
    quietly summarize `between_i'
    return scalar between = r(sum)

    drop __tmp0 __tmp1 `w0n' `w1n' `wbar' `dvi' `vbar' `dwi' `within_i' `between_i'
end


* export table 

	tempname P
	postfile `P' str20 outcome ///
		double early late delta within between within_pct ///
		using "`c(tmpdir)'/decomp_main_tmp.dta", replace

* pooled results (weights already in file; we renormalize inside program)
	quietly _one_decomp y_hh_pt0 y_hh_pt1, w0(w_hh0) w1(w_hh1)
	scalar Y0 = r(mean0)
	scalar Y1 = r(mean1)
	scalar dY = r(d)
	scalar Wy = r(within)
	scalar By = r(between)
	scalar Wpct = 100*Wy/dY
	post `P' ("Productivity") (Y0) (Y1) (dY) (Wy) (By) (Wpct)

	quietly _one_decomp Ltot_hh_pt0 Ltot_hh_pt1, w0(w_hh0) w1(w_hh1)
	scalar A0 = r(mean0)
	scalar A1 = r(mean1)
	scalar dA = r(d)
	scalar WA = r(within)
	scalar BA = r(between)
	scalar Wpct = 100*WA/dA
	post `P' ("Total labor") (A0) (A1) (dA) (WA) (BA) (Wpct)

	quietly _one_decomp Lfam_hh_pt0 Lfam_hh_pt1, w0(w_hh0) w1(w_hh1)
	scalar F0 = r(mean0)
	scalar F1 = r(mean1)
	scalar dF = r(d)
	scalar WF = r(within)
	scalar BF = r(between)
	scalar Wpct = 100*WF/dF
	post `P' ("Family labor") (F0) (F1) (dF) (WF) (BF) (Wpct)

	quietly _one_decomp Lhir_hh_pt0 Lhir_hh_pt1, w0(w_hh0) w1(w_hh1)
	scalar H0 = r(mean0)
	scalar H1 = r(mean1)
	scalar dH = r(d)
	scalar WH = r(within)
	scalar BH = r(between)
	scalar Wpct = 100*WH/dH
	post `P' ("Hired labor") (H0) (H1) (dH) (WH) (BH) (Wpct)

	postclose `P'

	use "`c(tmpdir)'/decomp_main_tmp.dta", clear

	format early late delta within between %9.2f
	format within_pct %9.1f

	cap erase "$export1/decomp_main.tex"
	file open fh using "$export1/decomp_main.tex", write replace
	file write fh "\begin{table}[htbp]" _n ///
				"\centering" _n ///
				"\caption{Within--between decomposition of productivity and labor intensity}" _n ///
				"\label{tab:decomp_main}" _n ///
				"\small" _n ///
				"\begin{tabular}{lrrrrrr}" _n ///
				"\toprule" _n ///
				" & \multicolumn{1}{c}{Early} & \multicolumn{1}{c}{Late} & \multicolumn{1}{c}{\$\Delta\$} & \multicolumn{1}{c}{Within} & \multicolumn{1}{c}{Between} & \multicolumn{1}{c}{Within (\%\$\Delta\$)} \\" _n ///
              "\midrule" _n

	quietly {
		forvalues i=1/`=_N' {
			local out = outcome[`i']
			file write fh "`out' & " %9.2f early[`i'] " & " %9.2f late[`i'] " & " %9.2f delta[`i'] ///
							" & " %9.2f within[`i'] " & " %9.2f between[`i'] " & " %9.1f within_pct[`i'] " \\" _n
		}
	}

	file write fh "\bottomrule" _n ///
				"\multicolumn{7}{p{0.92\linewidth}}{\footnotesize Notes: Early = 2008--2011; Late = 2018--2021. Labor outcomes are measured as $\mathrm{asinh}(\tilde{L}/A)$ where $\tilde{L}$ is plot labor days winsorized at the 1st/99th percentiles within country and $A$ is GPS-measured plot area. Decomposition uses midpoint (Shapley) weights. Percent contributions can exceed 100 in absolute value when within and between components offset.} \\" _n ///
				"\end{tabular}" _n ///
				"\end{table}" _n
	file close fh

* appendix 
	use "$decomp", clear
	levelsof country, local(ctrys)

	cap erase "$export1/decomp_appendix_bycountry.tex"
	file open gh using "$export1/decomp_appendix_bycountry.tex", write replace

	file write gh "\begin{table}[htbp]" _n ///
				"\centering" _n ///
				"\caption{Within--between decomposition by country (balanced households)}" _n ///
				"\label{tab:decomp_appendix_country}" _n ///
				"\scriptsize" _n ///
				"\begin{tabular}{llrrrrrrr}" _n ///
				"\toprule" _n ///
				"Country & Outcome & Early & Late & \$\Delta\$ & Within & Between & Within (\%\$\Delta\$) & Between (\%\$\Delta\$) \\" _n ///
				"\midrule" _n

	foreach c of local ctrys {

		preserve
		keep if country == "`c'"

* build a small 4-row dataset for this country
		tempname Q
		postfile `Q' str15 outcome ///
			double early late delta within between within_pct between_pct ///
			using "`c(tmpdir)'/ctry_tmp.dta", replace

		quietly _one_decomp y_hh_pt0 y_hh_pt1, w0(w_hh0) w1(w_hh1)
		scalar a0=r(mean0)  \ scalar a1=r(mean1) \ scalar da=r(d)
		scalar aw=r(within) \ scalar ab=r(between)
		scalar ap=100*aw/da \ scalar bp=100*ab/da
		post `Q' ("Productivity") (a0) (a1) (da) (aw) (ab) (ap) (bp)
	
		quietly _one_decomp Ltot_hh_pt0 Ltot_hh_pt1, w0(w_hh0) w1(w_hh1)
		scalar a0=r(mean0)  \ scalar a1=r(mean1) \ scalar da=r(d)
		scalar aw=r(within) \ scalar ab=r(between)
		scalar ap=100*aw/da \ scalar bp=100*ab/da
		post `Q' ("Total labor") (a0) (a1) (da) (aw) (ab) (ap) (bp)

		quietly _one_decomp Lfam_hh_pt0 Lfam_hh_pt1, w0(w_hh0) w1(w_hh1)
		scalar a0=r(mean0)  \ scalar a1=r(mean1) \ scalar da=r(d)
		scalar aw=r(within) \ scalar ab=r(between)
		scalar ap=100*aw/da \ scalar bp=100*ab/da
		post `Q' ("Family labor") (a0) (a1) (da) (aw) (ab) (ap) (bp)

		quietly _one_decomp Lhir_hh_pt0 Lhir_hh_pt1, w0(w_hh0) w1(w_hh1)
		scalar a0=r(mean0)  \ scalar a1=r(mean1) \ scalar da=r(d)
		scalar aw=r(within) \ scalar ab=r(between)
		scalar ap=100*aw/da \ scalar bp=100*ab/da
		post `Q' ("Hired labor") (a0) (a1) (da) (aw) (ab) (ap) (bp)

		postclose `Q'
		use "`c(tmpdir)'/ctry_tmp.dta", clear
		format early late delta within between %9.2f
		format within_pct between_pct %9.1f

* write rows
		forvalues i=1/`=_N' {
			local out = outcome[`i']
			local ccell = cond(`i'==1, "`c'", "")
			file write gh "`ccell' & `out' & " %9.2f early[`i'] " & " %9.2f late[`i'] " & " %9.2f delta[`i'] ///
						" & " %9.2f within[`i'] " & " %9.2f between[`i'] " & " %9.1f within_pct[`i'] " & " %9.1f between_pct[`i'] " \\" _n
		}
		file write gh "\addlinespace" _n

		restore
	}

	file write gh "\bottomrule" _n ///
				"\multicolumn{9}{p{0.94\linewidth}}{\footnotesize Notes: Same definitions as Table~\ref{tab:decomp_main}. Country-specific results use weights renormalized within country and period. Percent contributions can exceed 100 in absolute value when within and between components offset.} \\" _n ///
				"\end{tabular}" _n ///
				"\end{table}" _n
	file close gh	
	
	restore
*/

* image will be made in python 	
	
***********************************************************************
**# 5 - model 3 - farm level
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
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id hh_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 ///
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
					
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group of hh"
			
	svyset, 	clear
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered)

	
* run model 3
	*erase 		"$export1/tables/model3/yield.tex"
	*erase 		"$export1/tables/model3/yield.txt"
	

	svy: 		reg  ln_yield_cp $selbaseline 

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
				
				
***********************************************************************
**# 6 - model 4 - hh FE 
***********************************************************************

* drop if Mali
	drop if 	country == "Mali"
	
* clear survey design settings 
	svyset,		clear 
	
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)

				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	global 		remove  d_Ethiopia d_Mali d_Malawi d_Niger d_Nigeria o.d_Tanzania
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(hh_id_obs) // many reps fail due to collinearities in controls

	estimates 	store D
*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model4/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append



***********************************************************************
**# 7 - model 5 - plot-manager
***********************************************************************		

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	*** crop is our vairalbe 
	*** 83,753 observations dropped
	
	replace 	crop_shock = . if crop_shock == .a	
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country wave hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	
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
	display 	"$selbaseline"

* collapse the data to a plot manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id manager_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(plot_manager_id)
						
		
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
	
* drop mali 
	drop if 	country == "Mali"
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	
	drop if 	float(temp_weight_test) != float(total_wgt_survey)
	assert 		float(temp_weight_test)==float(total_wgt_survey)
	drop 		scalar temp_weight_test

* survey design
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)


* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	*global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)

* estimate model 5
	*erase 		"$export1/tables/model5/yield.tex"
	*erase 		"$export1/tables/model5/yield.txt"
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(manager_id_obs) 
	*local lb 	= _b[year] - invttail(e(df_r),0.025)*_se[year]
	*local ub 	= _b[year] + invttail(e(df_r),0.025)*_se[year]
				
	estimates 	store E
	*test 		$test
	*local 		F1 = r(F)
	*outreg2 	using "$export1/tables/model5/yield.tex",  /// 
				keep(c.year  $sel ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append


***********************************************************************
**# 8 - model 6 - cluster 
***********************************************************************	

* open dataset
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

	drop if 	ea_id_obs == .
	drop if 	pw == .
	
* drop if main crop if missing
	*drop if 	main_crop == "" 
	*** main crop if their variable
	drop if		crop == . 
	* crop is our variable
	
	replace 	crop_shock = . if crop_shock == .a	
	
* generate necessary variables 
	gen			ln_yield_cp = asinh(yield_cp)
	
* generetar hh_id, plot_manager_id, plot_id, parcel_id, cluster_id
	egen 		hh_id = group(country wave hh_id_obs)
 	egen 		plot_manager_id = group(country wave manager_id_obs)
	egen 		plot_id = group(country wave plot_id_obs)
	egen 		parcel_id = group(country wave parcel_id_obs)
	egen 		cluster_id = group( country wave ea_id_obs)
	
	
	gen 		ln_dist_popcenter = asinh(dist_popcenter)
	
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
	display 	"$selbaseline"

* collapse the data to a hh level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop cluster_id hh_id_obs /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 ///
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
	display 	"$selbaseline"

* collapse the data to a plot manager level 
	collapse 	(first) country survey admin_1* admin_2* admin_3* crop   /// 
				(max) female_manager formal_education_manager hh_size ea_id_obs /// 
				hh_electricity_access livestock hh_shock lat_modified lon_modified /// 
				dist_popcenter total_wgt_survey strataid intercropped pw urban /// 
				ln_dist_popcenter ///
				soil_fertility_index d_* indc_* ///
				(sum) yield_cp harvest_value_cp seed_value_cp fert_value_cp total_labor_days /// 
				(sum) plot_area_GPS /// 
				(max) organic_fertilizer inorganic_fertilizer used_pesticides crop_shock /// 
				plot_owned irrigated /// 
				(mean) age_manager year ///
				(first) v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 ///
				(count) mi_* /// 
				(count) n_yield_cp = yield_cp n_harvest_value_cp = harvest_value_cp ///  
				n_seed_value_cp = seed_value_cp n_fert_value_cp = fert_value_cp /// 
				n_total_labor_days = total_labor_days n_plot_area_GPS = plot_area_GPS, /// 
				by(cluster_id)
						
		
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
	
	
* create weight adj
	bys 		country survey : egen double sum_weight_wave_surveypop = sum(pw)
	gen 		double scalar =  total_wgt_survey / sum_weight_wave_surveypop
	gen 		double wgt_adj_surveypop = scalar * pw 
	bys 		country survey : egen double temp_weight_test = sum(wgt_adj_surveypop)
	assert 		float(temp_weight_test) == float(total_wgt_survey)
	drop 		scalar temp_weight_test
	
* attach labels
	lab 		values crop crop
	lab var		crop "Main Crop group - cluster"
				
* survey design
	svyset 		ea_id_obs [pweight=wgt_adj_surveypop], strata(strata) singleunit(centered) /// 
				bsrweight(ln_yield_cp year ln_plot_area_GPS ln_total_labor_days /// 
				ln_fert_value_cp ln_seed_value_cp used_pesticides organic_fertilizer /// 
				irrigated intercropped crop_shock hh_shock hh_size /// 
				formal_education_manager female_manager age_manager hh_electricity_access /// 
				urban plot_owned v02_rf1 v03_rf1 v04_rf1 v10_rf1 v14_rf1 /// 
				soil_fertility_index d_* indc_*) vce(bootstrap)
				
* describe survey design 
	svydes 		ln_yield_cp, single generate(d)
	
* determine how many ea exist
	bysort		strataid (ea_id_obs): gen ID = sum(ea_id_obs != ea_id_obs[_n - 1])
	
* determine max number of ea per strata
	bysort		strataid: egen count_ea = max(ID)
	
* drop singletons (singleton strta can cause errors in variance estimation)
	drop if 	count_ea < 2 // drop singletons 
	
* generate bootstrap weights
	bsweights 	bsw, n(-1) reps(500) seed(123)

	*global 		remove  2.Country 3.Country 4.Country 5.Country 6.Country 
	* included in main : 311bn.agro_ecological_zone 314bn.agro_ecological_zone 1.country_dummy3#c.tot_precip_cumulmonth_lag3H2
	*global 		sel : list global(selbaseline) - global(remove)
	display 	"$sel"
	
* estimate model 4
*	erase 		"$export1/tables/model4/yield.tex"
*	erase 		"$export1/tables/model4/yield.txt"

	*xtset 		hh_id_obs wave	
	*xtreg		ln_yield_USD $sel, fe
	
	bs4rw, 		rw(bsw*)  : areg ln_yield_cp $sel /// 
				[pw = wgt_adj_surveypop],absorb(ea_id_obs) // many reps fail due to collinearities in controls

	estimates 	store F
*	test 		$test
*	local 		F1 = r(F)
*	outreg2 	using "$export1/tables/model6/yield.tex",  /// 
				keep(c.year  $inputs_cp $controls_cp ) /// 
				ctitle("Geovariables and weather controls - FE")  /// 
				addtext(Main crop FE, YES, Country FE, YES)  append
		
***********************************************************************
**# 9 - coefficient plot
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
				ylab(0.10 "10" 0.09 "9" 0.08 "8" 0.07 "7" 0.06 "6" 0.05 "5" 0.04 "4" 0.03 "3" 0.02 "2" /// 
				0.01 "1" 0 "0" -0.01 "-1" -0.02 "-2" -0.03 "-3" -0.04 "-4", labsize(small) grid) /// 
				ytitle(Annual productivity change (%)) vertical xsize(5)

*** END ***