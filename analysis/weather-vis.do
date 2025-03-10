* Project: rodrigo thesis 
* Created on: March 2025
* Created by: alj
* Edited by: rg
* Last edit: 9 March 2025 
* Stata v.18.0 

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* include Uganda (?)

* Note:
	* created a loop to create graphs starting at line 154
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	global export1 	"$output/graphs&tables"

* open log	
	cap log close
*	log 	using 		"$logout/summaryvis", append

***********************************************************************
**# 1 - load and process data
***********************************************************************

* load data 
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

***********************************************************************
**# 2 - generate total season distribution graphs by country
***********************************************************************

/*
* total season rainfall - ethiopia
	twoway  (kdensity v05_rf2 if country == "Ethiopia", color(gray%30) recast(area)) ///
			(kdensity v05_rf3 if country == "Ethiopia", color(vermillion%30) recast(area)) ///
			(kdensity v05_rf4 if country == "Ethiopia", color(sea%30) recast(area)) ///
			, xtitle("") xscale(r(0(2000)8000)) title("Ethiopia") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
			legend(pos(6) col(6) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "ERA5")) 

	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/eth_density_rf.gph", replace
		*graph export 	"$export1/figures/density_rf/eth_density_rf.pdf", as(pdf) replace

* total season rainfall - malawi	
twoway  (kdensity v05_rf2 if country == "Malawi", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Malawi", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Malawi", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)3000)) title("Malawi") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)

	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/mwi_density_rf.gph", replace
		*graph export 	"$export1/figures/density_rf/mwi_density_rf.pdf", as(pdf) replace

* total season rainfall - mali
twoway  (kdensity v05_rf2 if country == "Mali", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Mali", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Mali", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)2500)) title("Mali") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)


	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/mli_density_rf.gph", replace		
		*graph export 	"$export1/figures/density_rf/mli_density_rf.pdf", as(pdf) replace

* total season rainfall - niger	
twoway  (kdensity v05_rf2 if country == "Niger", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Niger", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Niger", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)2500)) title("Niger") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)


	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/ngr_density_rf.gph", replace
		*graph export 	"$export1/figures/density_rf/ngr_density_rf.pdf", as(pdf) replace

* total season rainfall - nigeria
twoway  (kdensity v05_rf2 if country == "Nigeria", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Nigeria", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Nigeria", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)3000)) title("Nigeria") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)
			

	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/nga_density_rf.gph", replace
		*graph export 	"$export1/figures/density_rf/nga_density_rf.pdf", as(pdf) replace

* total season rainfall - tanzania	
twoway  (kdensity v05_rf2 if country == "Tanzania", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Tanzania", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Tanzania", color(sea%30) recast(area)) ///
        , xtitle("Total Seasonal Rainfall (mm)") xscale(r(0(500)3000)) title("Tanzania") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)


	* save the graph as .gph (to later combine)
		*graph save 		"$export1/figures/density_rf/tza_density_rf.gph", replace
		*graph export 	"$export1/figures/density_rf/tza_density_rf.pdf", as(pdf) replace

* create a panel
*graph combine "$export1/figures/density_rf/eth_density_rf.gph" ///
              "$export1/figures/density_rf/mwi_density_rf.gph" ///
              "$export1/figures/density_rf/mli_density_rf.gph" ///
              "$export1/figures/density_rf/ngr_density_rf.gph" ///
              "$export1/figures/density_rf/nga_density_rf.gph" ///
              "$export1/figures/density_rf/tza_density_rf.gph", ///
              rows(2) cols(3) imargin(3) title("Seasonal Rainfall Density by Country")
*/


* total season rainfall - uganda	
*twoway  (kdensity v05_rf2 if country == "Uganda", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Uganda", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Uganda", color(sea%30) recast(area)) ///
        , xtitle("Total Seasonal Rainfall (mm)") xscale(r(0(500)3500)) title("Uganda") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)
			
*	graph export 	"$export1\uga_density_rf.pdf", as(pdf) replace

*	grc1leg2 		"$sfig/eth_density_rf.gph" "$sfig/mwi_density_rf.gph" ///
						"$sfig/ngr_density_rf.gph" "$sfig/nga_density_rf.gph"   ///
						"$sfig/tza_density_rf.gph" "$sfig/uga_density_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
*	graph export 	"$export1\density_rf.pdf", replace			

* if those middle parts ran this would work but it isn't working
* can try and fix 
	

* create an indicator for values > 2,500 mm
	foreach 		var in v05_rf2 v05_rf3 v05_rf4 {
				gen 		`var'_mod = `var'
				replace 	`var'_mod = 2500 if `var' > 2500
		}

* define axis ranges 
	local 			x_range "xscale(range(0 2500)) xlabel(0(500)2000 2500 `"2,500+"', nogrid labsize(vsmall))"
	local 			y_range "yscale(range(0 0.008)) ylabel(0(0.002)0.008, nogrid labsize(small))"

* loop graphs by country 
	foreach 		country in Ethiopia Malawi Mali Niger Nigeria Tanzania {
				twoway 		(kdensity v05_rf2_mod if country == "`country'", color(gray%30) recast(area)) ///
							(kdensity v05_rf3_mod if country == "`country'", color(vermillion%30) recast(area)) ///
							(kdensity v05_rf4_mod if country == "`country'", color(sea%30) recast(area)), ///
							xtitle("", size(vsmall)) `x_range' `y_range' title("`country'") ///
							ytitle("") ///
							legend(pos(6) col(6) label(1 "CHIRPS") label(2 "CPC") label(3 "ERA5"))

    * save the graph as .gph (to later combine)
				graph 		save "$export1/figures/density_rf/`=lower("`country'")'_density_rf.gph", replace
				graph 		export "$export1/figures/density_rf/`=lower("`country'")'_density_rf.pdf", as(pdf) replace
		}


* create a panel			
	grc1leg2 		"$export1/figures/density_rf/ethiopia_density_rf.gph" /// 
					"$export1/figures/density_rf/mali_density_rf.gph" ///
					"$export1/figures/density_rf/malawi_density_rf.gph" /// 
					"$export1/figures/density_rf/niger_density_rf.gph" /// 
					"$export1/figures/density_rf/nigeria_density_rf.gph" /// 
					"$export1/figures/density_rf/tanzania_density_rf.gph", ///
					rows(2) cols(3) iscale(.5) title("Total Season Rainfall Density by Country") commonscheme
					
	graph 			export "$export1/figures/density_rf/all_countries_density_rf", as(pdf) replace
					
					
***********************************************************************
**# 3 - end matter
***********************************************************************



* close the log
*	log	close

/* END */
