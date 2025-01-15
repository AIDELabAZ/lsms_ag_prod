* Project: Rodrigo thesis
* Created on: 15 January 2025
* Created by: alj
* Edited on: 15 January 2025
* Edited by: alj
* Stata v.18.5

* does
	* 

* assumes
	* 
	
* TO DO:
	* 
	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/countries"
	global 	logout 		"$data/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/model1", append

	
***********************************************************************
**# 1 - data 
***********************************************************************

* data

	use 		"$root/aggregate/allrounds_final", clear		
	
***********************************************************************
**# 2 - run replication
***********************************************************************
	
* generate log yield
	gen				ln_yield1 = asinh(yield_kg1)
	gen 			ln_yield2 = asinh(yield_kg2)
	
* generate country dummy
	tab 			country, generate(country_dummy)

* generate time trend
	sort			wave
	egen			tindex = group(wave)
	
* estimate model 1 for yield 1 
	reg				ln_yield1 tindex country_dummy1 country_dummy2 country_dummy3 ///
						country_dummy4 country_dummy5 country_dummy6 [aweight = pw], ///
						vce(cluster ea_id_merge)

* and again for yield 2 
 * ... 

									