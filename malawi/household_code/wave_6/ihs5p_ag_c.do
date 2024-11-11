* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 11 November 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop plot size 

* assumes
	* access to MWI 6 raw data - PANEL
	
* TO DO:
	* done 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		root 	= 	"$data/raw_lsms_data/malawi/wave_6/raw"	
	global		export 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/wave_6"
	global		logout 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/logs"
	global	 	temp 	= 	"$data/lsms_ag_prod_data/refined_data/malawi/tmp"
	
* open log
	cap 	log			close
	log 	using 		"$logout/mwi_ag_mod_c19", append

* **********************************************************************
* 1 - clean plot area 
* **********************************************************************

* load data
	use 			"$root/ag_mod_c_19.dta", clear
	
* drop observations with missing plot id variable or garden id variable 
	summarize 		if missing(plotid)
	drop 			if missing(plotid)
	*** 0 dropped
	summarize 		if missing(gardenid)
	drop			if missing(gardenid)
	*** 0 dropped 
	isid 			y4_hhid gardenid plotid
	
* generate self-reported land area in hectares 
	tab 			ag_c04a, missing 
	*** 9 missing 
	generate		conversion = 1 if ag_c04b == 2
	replace 		conversion = 0.40468564 if ag_c04b == 1
	*** 5266 changes 
	replace 		conversion = 0.0001 if ag_c04b == 3 
	*** 239 changes
	drop			if ag_c04b == 4 
	*** 15 observations dropped 
	generate 		selfreport = conversion * ag_c04a if ag_c04a!=0
	summarize		selfreport, detail	
	*** mean = 0.29, median = 0.20 
	
* generate GPS land area of plot in hectares 
* as a starting point, expect that GPS is more accurate than self-report 
*** THIS IS THE ASSUMPTION EVEN IF I DON'T AGREE - GPS IS MORE ACCURATE 
	summarize 		ag_c04c, detail 
	generate 		gps = ag_c04c * 0.40468564 if ag_c04c!=0
	summarize 		gps, detail
	*** mean = 0.28, median = 0.21
	
* compare GPS and self-report & look for outliers 
	summarize 		gps, detail
	*** same command as above used in order to easily access r-class stored results
	list 			gps selfreport if !inrange(gps,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & !missing(gps)	
	*** look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	*** these appear to be incorrect GPS values - GPS almost always greater 
	*** 95 values or so

* GPS on larger side of self-report 
	tabulate 		gps if gps>2, plot					
	*** a few high values but most look reasonable - largest is 15.8 
	*** only 15 observations here 
	list 			gps selfreport if gps>3 & !missing(gps), sep(0)	
	*** there are < 10 obs≤3 ha, so let's look more closely at the relationship between self-report & GPS for observations >3
	*** but self report is different by A LOT in all cases: for example 3.6 for one at GPS, but clocked at 0.12 
	
* GPS on the smaller side vs self-report 
	tabulate 		gps if gps<0.1						
	*** GPS data distribution is lumpy for small plots due to the precision constraints of the technology 
	*** in this group there are 1284 obs 
	list 			gps selfreport if gps<0.01, sep(0)		
	*** still lots of mismatches, scale of 110
	
* correlations
	pwcorr 			selfreport gps
	*** 0.69 - decent
	pwcorr 			selfreport gps if inrange(gps,0.001,3)
	*** pretty much the same
	*** tested down to 0.001 to 1 - really no differences, always around same value
	*** my inclincation, in reviewing, is to not trust gps 
	*** but wb says to trust gps 
	scatter			selfreport gps
	*** THIS IS THE ASSUMPTION GPS > SELF REPORT 

* make plotsize using GPS area if it is within reasonable range
	generate 		plotsize = gps 
	*** 311 missing values 
	replace			plotsize = selfreport if plotsize == . 
	*** 299 changes
	summarize 			selfreport gps plotsize	
	*** do we have some self-report information where we are missing plotsize?
	summarize 			selfreport if missing(plotsize), detail
	*** nope no observations 

* merge  district variables 
	merge m:1 y4_hhid using "$root/hh_mod_a_filt_19.dta", keepusing(district) assert (2 3) keep (3) nogenerate
	*** all 5553 matched	
					
* cannot do anyting about missing plot sizes from above 
	drop if plotsize == . 
	* drop 12 observations 
	
* manipulate variables for export
	label 			variable plotsize		"Plot Size (ha)"
	
	pwcorr 			plotsize gps selfreport 

* restrict to variables of interest 
	keep  			y4_hhid gardenid plotid plotsize
	order 			y4_hhid gardenid plotid plotsize 

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************
	
	compress
	describe
	summarize 
	
* save data
	save 			"$export/ag_mod_c_19.dta", replace

* close the log
	log			close


/* END */