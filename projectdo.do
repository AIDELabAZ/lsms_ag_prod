* Project: LSMS_ag_prod
* Created on: Sep 2024
* Created by: rg
* Edited on: 20 Sep 2024
* Edited by: rg
* Stata v.18, mac

* does
	* establishes an identical workspace between users
	* sets globals that define absolute paths
	* serves as the starting point to find any do-file, dataset or output
	* runs all do-files needed for data work
	* loads any user written packages needed for analysis

* assumes
	* access to all data and code

* TO DO:
	* add run time 


* **********************************************************************
* 0 - setup
* **********************************************************************

* set $pack to 0 to skip package installation
	global 			pack 	0
		
* Specify Stata version in use
    global stataVersion 18.0    // set Stata version
    version $stataVersion

* **********************************************************************
* 0 (a) - Create user specific paths
* **********************************************************************

* Define root folder globals

if `"`c(username)'"' == "jdmichler" {
        global 		code  	"C:/Users/jdmichler/git/AIDELabAZ/lsms_ag_prod"
		global 		data	"C:/Users/jdmichler/OneDrive - University of Arizona/weather_and_agriculture"
    }
if `"`c(username)'"' == "aljos" {
        global 		code  	"C:/Users/aljos/git/weather_and_agriculture/lsms_ag_prod"
		global 		data	"C:/Users/aljos/OneDrive - University of Arizona/weather_and_agriculture/lsms_base"
		global 		output	"C:/Users/aljos/OneDrive - University of Arizona/ag_prod" 
		
    }	
if `"`c(username)'"' == "rodrigoguerra" {
        global 		code  	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/Documents/GitHub/lsms_ag_prod"
		global 		data	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/weather_and_agriculture/lsms_base" 
		global 		output	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/ag_prod" 
    }

* **********************************************************************
* 0 (b) - Check if any required packages are installed:
* **********************************************************************

* install packages if global is set to 1
if $pack == 0 {
	
	* for packages/commands, make a local containing any required packages
    * temporarily set delimiter to ; so can break the line
    #delimit ;		
	loc userpack = "blindschemes mdesc estout distinct winsor2 unique 
                    palettes catplot colrspace carryforward missings 
                    coefplot" ;
    #delimit cr
	
	* install packages that are on ssc	
		foreach package in `userpack' {
			capture : which `package', all
			if (_rc) {
				capture window stopbox rusure "You are missing some packages." "Do you want to install `package'?"
				if _rc == 0 {
					capture ssc install `package', replace
					if (_rc) {
						window stopbox rusure `"This package is not on SSC. Do you want to proceed without it?"'
					}
				}
				else {
					exit 199
				}
			}
		}

	* install -weather- package
		net install WeatherConfig, ///
		from(https://jdavidm.github.io/) replace

	* install -xfill and dm89_1 - packages
		net install xfill, 	replace from(https://www.sealedenvelope.com/)
		
	* update all ado files
		ado update, update

	* set graph and Stata preferences
		set scheme plotplain, perm
		set more off
}

* **********************************************************************
* 1 - run weather data cleaning .do file
* **********************************************************************

/*	this code requires access to the weather data sets, which are confidential
	and held by the World Bank. They are not publically available

	do 			"$code/ethiopia/weather_code/eth_ess_masterdo.do"
	do 			"$code/malawi/weather_code/mwi_ihs_masterdo.do"
	do 			"$code/niger/weather_code/ngr_ecvma_masterdo.do"
	do 			"$code/nigeria/weather_code/nga_ghs_masterdo.do"
	do 			"$code/tanzania/weather_code/tza_nps_masterdo.do"
	do 			"$code/uganda/weather_code/uga_unps_masterdo.do"
*/

* **********************************************************************
* 2 - run household data cleaning .do files and merge with weather data
* **********************************************************************

/*	this code requires a user to have downloaded the publically available 
	household data sets and placed them into the folder structure detailed
	in the readme file accompanying this repo.

	do 			"$code/ethiopia/household_code/eth_hh_masterdo.do"
	do 			"$code/malawi/household_code/mwi_hh_masterdo.do"
	do 			"$code/niger/household_code/ngr_hh_masterdo.do"
	do 			"$code/nigeria/household_code/nga_hh_masterdo.do"
	do 			"$code/tanzania/household_code/tza_hh_masterdo.do"
	do 			"$code/uganda/household_code/uga_hh_masterdo.do"
*/

* **********************************************************************
* 2 - run analysis .do files
* **********************************************************************

