use "https://github.com/imaddowzimet/StataPrograms/raw/master/Statalist%20Dataset%20and%20Programs/StatalistPosts.dta", clear


///////////
* Graphs:
///////////


* Statalist posts over time
preserve
gen count = 1
collapse (sum) count, by(Date)
graph twoway (line count Date, color("gs5"))                                    ///
             (lowess count Date, color("midblue")),                             ///
              scheme(s1color) ytitle("Number of posts") xtitle("")              ///
			  tlabel(01jan2014 01jan2015 01jan2016 01jan2017 01jan2018 01jan2019 01jan2020, format(%dm-CY))   ///
			  title("Frequency of Statalist posts, by day, 2014-2020.",         ///
			         size(msmall))                                              ///
		      legend(off)                                                       ///
			  tline(31mar2014, lcolor("orange_red") lpattern("dash"))           ///
			  ttext(60 01apr2014 "<- Statalist's auspicious beginnings, March 31st, 2014", place(e) size(small)) name(graph1)


restore

* Statalist posts by year
preserve
gen count = 1
collapse (sum) count, by(year)
graph twoway (bar count year, fcolor("gs3") barw(.7)),                          ///
              scheme(s1color) ytitle("Number of posts") xtitle("")              ///
               title("Frequency of Statalist posts by year, 2014-2017.",        ///
			         size(msmall)) name(graph2) yscale(range(0 9000))           ///
					 ylabel(0(3000)9000)                                          


restore

* Number of posts by month, controlling for year
preserve
gen count = 1
collapse (sum) count, by(month year)
drop if count<200
regress count i.month i.year
margins i.month, post
mat a = e(b)
clear
svmat a
gen i=_n
reshape long a, i(i) j(month)

graph twoway (bar a month, fcolor("gs3") barw(.7)),                          ///
              scheme(s1color) ytitle("Number of posts") xtitle("")              ///
               title("Average frequency of Statalist posts by month (adjusting for year)",        ///
			         size(msmall)) name(graph3) yscale(range(0 900))           ///
					 ylabel(0(300)900) xlabel(1(1)12)                                        
restore


* Number of posts by day of week
preserve
gen count = 1
collapse (sum) count, by(dow)

graph twoway (bar count dow, fcolor("gs3") barw(.7)),                          ///
              scheme(s1color) ytitle("Number of posts") xtitle("")              ///
               title("Number of Statalist posts by day of week, pooled 2014-2017.",        ///
			         size(msmall)) name(graph4) yscale(range(0 6000))           ///
					 ylabel(0(2000)6000)  xlabel(0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday")                                        


restore

* How often are ssc commands mentioned?
* list of ssc commands from: http://www.haghish.com/statistics/stata-blog/stata-programming/ssc_stata_package_list.php)
include "https://raw.githubusercontent.com/imaddowzimet/StataPrograms/master/Statalist%20Dataset%20and%20Programs/ssccommands.doi"

* Remove command names that could potentially be referring to other things
local remove adjust array ascii barplot bic adjacent center cluster combine             ///
             contour contrast decompose delta detect digits distinct discrepancy        ///
			 dummies email effects dyads equation examples find groups grand            ///
			 hash hue integrate irr kernel levels margin marker markov median mediation ///
			 metadata missing moments nearest overlay panels parallel poverty           ///
			 pre preparation project pyramid python quantiles radar reformat           ///
			 reset running stack scores spaces spike split switch symmetry title       ///
			 tolerance twofold unique violin white zip spell 
local commands: list commands-remove			 

* Create dummies for each command (1= mentioned in post)
foreach mycommand of local commands {

	  gen `mycommand'=0
	  replace `mycommand'= 1 if strpos(titlestring, " `mycommand' ")

}
egen totalvalid= rowtotal(a2reg-_peers)
* only around 2% of posts mention valid ssc command names

* Create variables for total time each command was mentioned:
* this code also drops dummies for commands that were never mentioned 
foreach mycommand of varlist a2reg-_peers {
	di "`mycommand'"
	cap noi egen total`mycommand' = total(`mycommand')
	if !_rc {
		if total`mycommand'==0 {
			drop `mycommand'
			drop total`mycommand'
		}
	}
}

* Store totals in matrix, and sort
matrix totals = J(1,1,.)
foreach mycommand of varlist total* {
	
	matrix temp = `mycommand'[1]
	matrix rownames temp = "`mycommand'"
	matrix totals = totals \ temp
	
}
matrix totals = totals[2...,1]
matsort totals 1 "down"

* Barplot of top 5 commands
clear
set obs 5
gen command = ""
gen count   = .
local rownames: rownames totals
foreach mynum of numlist 1/5 {
	local command: word `mynum' of `rownames'
	di "`command'"
	replace command = "`command'" if _n == `mynum'
    replace count   = totals[`mynum',1] if _n == `mynum'
}

graph bar (asis) count, over(command, sort(1)) scheme(s1mono)                   ///
      title("5 most frequently cited SSC commands in Statalist post titles",    ///
      size(msmall)) name(barplot5) ytitle("Number of posts")     

exit







