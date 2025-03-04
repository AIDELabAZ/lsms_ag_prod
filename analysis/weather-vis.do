* Project: rodirgo thesis 
* Created on: 3 mars 2024
* Created by: alj
* Edited by: alj
* Last edit: 3 mars 2025 
* Stata v.18.5 

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/lsms_ag_prod_data/replication"  
	global export 	"$data/lsms_ag_prod_data/replication"
	global logout 	"$data/lsms_ag_prod_data/replication/analysis/logs"
	global export1 	"$output/graphs&tables"

* open log	
	cap log close
*	log 	using 		"$logout/summaryvis", append

* **********************************************************************
* 1 - load and process data
* **********************************************************************

* load data 
	use 		"$data/countries/aggregate/allrounds_final_weather_cp.dta", clear

* **********************************************************************
* 2 - generate total season distribution graphs by country
* **********************************************************************

* total season rainfall - ethiopia
	twoway  (kdensity v05_rf2 if country == "Ethiopia", color(gray%30) recast(area)) ///
			(kdensity v05_rf3 if country == "Ethiopia", color(vermillion%30) recast(area)) ///
			(kdensity v05_rf4 if country == "Ethiopia", color(sea%30) recast(area)) ///
			, xtitle("") xscale(r(0(2000)8000)) title("Ethiopia") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
			legend(pos(6) col(6) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "ERA5")) 
			*** previously at the end there was a line "saving("$export1/NAME", replace)"
			*** but it wasn't running so i cut it for now
			*** this came at the end of all of them

*	graph export 	"$export1\eth_density_rf.pdf", as(pdf) replace

* total season rainfall - malawi	
twoway  (kdensity v05_rf2 if country == "Malawi", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Malawi", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Malawi", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)2500)) title("Malawi") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)
			
*	graph export 	"$export1\mwi_density_rf.pdf", as(pdf) 

* total season rainfall - mali
twoway  (kdensity v05_rf2 if country == "Mali", color(gray%30) recast(area)) ///
        (kdensity v05_rf3 if country == "Mali", color(vermillion%30) recast(area)) ///
        (kdensity v05_rf4 if country == "Mali", color(sea%30) recast(area)) ///
        , xtitle("") xscale(r(0(500)2500)) title("Mali") ///
        ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small)) ///
        legend(off)
			
*	graph export 	"$export1\mli_density_rf.pdf", as(pdf) 

* total season rainfall - niger	
	twoway  (kdensity v05_rf1 if country == 4, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 4, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 4, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 4, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 4, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 4, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(100)800)) title("Niger (n = 3,913)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/ngr_density_rf", replace)
			
*	graph export 	"$xfig\ngr_density_rf.pdf", as(pdf) replace

* total season rainfall - nigeria
	twoway  (kdensity v05_rf1 if country == 5, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 5, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 5, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 5, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 5, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 5, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(500)3000)) title("Nigeria (n = 9,145)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/nga_density_rf", replace)
			
*	graph export 	"$xfig\nga_density_rf.pdf", as(pdf) replace

* total season rainfall - tanzania	
	twoway  (kdensity v05_rf1 if country == 6, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 6, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 6, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 6, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 6, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 6, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(2000)6000)) title("Tanzania (n = 9,916)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/tza_density_rf", replace)
			
*	graph export 	"$xfig\tza_density_rf.pdf", as(pdf) replace

* total season rainfall - uganda	
	twoway  (kdensity v05_rf1 if country == 7, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 7, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 7, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 7, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 7, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 7, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(5000)3500)) ///
			title("Uganda (n = 11,692)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/uga_density_rf", replace)	
			
*	graph export 	"$xfig\uga_density_rf.pdf", as(pdf) replace

*	grc1leg2 		"$sfig/eth_density_rf.gph" "$sfig/mwi_density_rf.gph" ///
						"$sfig/ngr_density_rf.gph" "$sfig/nga_density_rf.gph"   ///
						"$sfig/tza_density_rf.gph" "$sfig/uga_density_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
*	graph export 	"$xfig\density_rf.pdf", replace			

* if those middle parts ran this would work but it isn't working
* can try and fix 
	
			
* **********************************************************************
* 3 - end matter
* **********************************************************************

* close the log
*	log	close

/* END */