capture program drop unstack
program define unstack

////////////////////////////////////////////////////////////////////////////////
/* PROGRAM NOTES:  This program takes the matrix stored from estpost tab
two way, and stacks it so that it appears like a 'normal' two way crosstab.
(estpost tab normally stores two way tabulations as a one column matrix, which
is not normally how one would want to export it)
This is an update of a previous program (also called unstack), implemented in
a slightly different (and more robust) way than the original. It was updated
in mid-August of 2017, and the previous version was archived. 
*/
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////
* User input checks
////////////////////////////

* Store prefix, if any
local prefix  = e(prefix)

* Store command
local command  = e(cmd)
local command2 = e(subcmd)

* Store row and column variable names
local rowvar = e(rowvar)
local colvar = e(colvar)


* If user did not include estpost in previous command, exit with error
if "`command'"!="estpost" {

	noi di "Please include -estpost- before your command (it may need to be installed first)"
	exit
	
}

* If user did not run a tabulation, exit with error
if "`command2'"!="tabulate" {

	noi di "-unstack- can only be run after a two-way tabulation, with estpost specified"
	exit
	
}

* If user did not run a two-way tabulation, exit with error
if "`colvar'"=="" {

	noi di "-unstack- can only be run after a two-way tabulation, with estpost specified"
	exit
	
}

* Delete any previously stored matrices with common names
foreach mymatrix of newlist matrix row col cell count {
	capture matrix drop `mymatrix'
}


///////////////////////////
* Unstack code
/*
Where results are stored is slightly different for svy: and non svy: tabulations
so there are two slightly different implementations of the same idea below.
The code essentially works by taking advantage of the fact that -estpost- always
labels the "total" row in the same way; once we know which row the first "total"
is in, we can divide the total matrix length by that number to figure out how 
many categories the column variable has (we already know how many categories
the row variable has because the last category row number immediately before the
"total" label). The previous version of unstack used -levelsof- to count 
categories, but it broke when an if statement was used that dropped one of the 
column or row variables completely (it didn't give incorrect results, luckily, 
just didn't run); since this approach takes the number of categories from the 
matrix directly, it doesn't have this issue, and it's also much more concise.  
*/
///////////////////////////

if "`prefix'"=="svy" {                                                          // if svyset

	//////////////////
	* Svy code
	/////////////////
	
	* Rename stored matrices
	matrix tempmatrix = e(b)'                                                   // matrix displayed in results screen
	matrix temprow    = e(row)'                                                 // row percentages
	matrix tempcol    = e(col)'                                                 // col percentages
	matrix tempcell   = e(cell)'                                                // cell percentages
	matrix tempcount  = e(count)'                                               // weighted counts
	matrix templb     = e(lb)'                                                  // lower bound CI
	matrix tempub     = e(ub)'                                                  // upper bound CI
        matrix tempse     = e(se)'                                                  // standard error
	
	local totalrow = rownumb(matrix(tempmatrix), "Total")                       // locate first "Total" row
	local Nrows  = rowsof(matrix(tempmatrix))                                   // count total number of rows in matrix
	local iter   = `Nrows'/`totalrow'                                           // determine number of column variable categories
	

	
	foreach mymatrix of newlist matrix row col cell count lb ub se {               // for each stored matrix

		local beginrow = 1                                                      // set first row for first iteration
		local endrow   = `totalrow'                                             // set last row for first iteration

		foreach mynum of numlist 1/`iter' {                                     // for each column variable category
		
			matrix `mymatrix'`mynum'= temp`mymatrix'[`beginrow'..`endrow',1]    // grab the first nth rows, which correspond to all of the row categories plus the total category of the first column variable category
			
			* Grab the right column name, and label the column correctly
			matrix `mymatrix'`mynum'onebyone == temp`mymatrix'[`beginrow'..`beginrow',1]    // we just grab a 1x1 selection of the matrix we grabbed above because it makes it simpler to just grab one column variable name (not repeated sets)
			local colname: roweq `mymatrix'`mynum'onebyone                      // the column variable name is stored in the row equation, so we extract it from there
			matrix colnames `mymatrix'`mynum' = "`colname'"                     // and then use it to label our nx1 matrix
		
			if `mynum' == 1 {                                                   // if this is the first iteration of the loop, initialize matrix
				matrix `mymatrix' = `mymatrix'`mynum'
			}
			else {                                                              // if it's not, add to the existing matrix column by column
				matrix `mymatrix' = `mymatrix',`mymatrix'`mynum'
			}
		
			* Drop temporary matrices 
			matrix drop `mymatrix'`mynum' `mymatrix'`mynum'onebyone
			
			* Advance beginning and end rows for next iteration of loop
			local beginrow = 1 + `endrow'                                       // the new beginning row is just the last end row +1
			local endrow = `endrow' +`totalrow'                                 // and the new end row is the last endrow plus the number of row variable categories including the total
		
		}
		
		* Delete row equations (since these are now stored as column labels)
		matrix roweq `mymatrix' = ""           
		
		* drop temporary matrix
		matrix drop temp`mymatrix'
	}
* let the user know where the matrices are
display in blue  "Matrix of weighted counts stored in: count"
display  "Matrix of row percentages stored in: row"
display  "Matrix of column percentages stored in: col"
display  "Matrix of cell percentages stored in: cell"
display  "Matrix of lower bounds of 95% confidence intervals of displayed statistics stored in: lb"
display  "Matrix of upper bounds of 95% confidence intervals of displayed statistics stored in: ub"
display  "Matrix of standard errors of displayed statistics stored in: se"

}
else {                                                                          // if not svyset 

	////////////////
	* Non-svy code
	* Note that this code is almost identical to the code above, and so 
	* the comments are not repeated except where they differ. 
	////////////////
	
	* Rename stored matrices
	matrix tempcount  = e(b)'                                                   // Ns
	matrix temprow    = e(rowpct)'                                              // row percentages
	matrix tempcol    = e(colpct)'                                              // col percentages
	matrix tempcell   = e(pct)'                                                 // cell percentages
	
	local totalrow = rownumb(matrix(tempcount), "Total")
	local Nrows  = rowsof(matrix(tempcount))
	local iter   = `Nrows'/`totalrow'
	
	foreach mymatrix of newlist row col cell count {
	
		local beginrow = 1
		local endrow   = `totalrow'
	
		foreach mynum of numlist 1/`iter' {
		
			matrix `mymatrix'`mynum'= temp`mymatrix'[`beginrow'..`endrow',1] 
			
			* Grab the right column name, and label the column correctly
			matrix `mymatrix'`mynum'onebyone == temp`mymatrix'[`beginrow'..`beginrow',1] 
			local colname: roweq `mymatrix'`mynum'onebyone
			matrix colnames `mymatrix'`mynum' = "`colname'"
		
			if `mynum' == 1 {
				matrix `mymatrix' = `mymatrix'`mynum'
			}
			else {
				matrix `mymatrix' = `mymatrix',`mymatrix'`mynum'
			}
			
			* Drop temporary matrices 
			matrix drop `mymatrix'`mynum' `mymatrix'`mynum'onebyone
			
			* Advance rows 
			local beginrow = 1 + `endrow' 
			local endrow = `endrow' +`totalrow'
		
		}
		
		* Delete row equations
		matrix roweq `mymatrix' = ""
	
		* drop temporary matrix
		matrix drop temp`mymatrix'
	}

* let the user know where the matrices are
display in blue  "Matrix of weighted counts stored in: count"
display  "Matrix of row percentages stored in: row"
display  "Matrix of column percentages stored in: col"
display  "Matrix of cell percentages stored in: cell"
			
}

///////////////////////////////////////////////////////////////////////
* Special case: If value labels have the form "#.name", estpost doesn't 
* store them in its matrix. This code resolves this issue, and relabels
* the matrix rows and columns
////////////////////////////////////////////////////////////////////////
if `"`e(labels)'"'!="" {                                                          // if stored row labels exist

	* Put the stored labels in a variable (which we will delete later) 
	qui gen _rowlabels1987 = e(labels) if _n == 1
	
	* Remove "extra characters" from what estpost stores
	while regexm(_rowlabels1987, "[1-9]+[ ]") {
		
		qui replace _rowlabels1987 = regexr(_rowlabels1987, "[1-9]+[ ]", "") if _n == 1
	
	}
	* Remove the extra designations estpost stores if there are missing values
	qui replace _rowlabels1987 = regexr(_rowlabels1987, "_missing_[a-z]*", "") if _n == 1
	foreach mymissingcode of numlist 97/122 {                                   // this may no longer be necessary; estpost used to handle missing value codes in a slightly different way, but it seems like it changed (I'm not sure of the precise version number when it did). It doesn't break anything so am leaving it in in case anyone is using an old version of estpost. 
		
		qui replace _rowlabels1987 = regexr(_rowlabels1987, "_missing_`=char(`mymissingcode')'", "") if _n == 1
	
	}
	
	* Bring the label string back into a local, and drop the variable
	local a =  _rowlabels1987
	drop _rowlabels1987
	
	foreach mymatrix of newlist row col cell count {
	
		local check: word count `a'                                             // make sure that we have the same number of value labels as we do rows
		if `=`totalrow'-1'==`check' {
			mat rownames `mymatrix' = `a' "Total"
	    }
	
	}
}
if `"`e(eqlabels)'"'!="" {

	* Put the stored labels in a variable (which we will delete later) 
	qui gen _collabels1987 = e(eqlabels) if _n == 1
	
	* Remove "extra characters" from what estpost stores
	while regexm(_collabels1987, "[1-9]+[ ]") {
		
		qui replace _collabels1987 = regexr(_collabels1987, "[1-9]+[ ]", "") if _n == 1
	
	}
	
	* Bring the label string back into a local, and drop the variable
	local a =  _collabels1987
	drop _collabels1987
	
	foreach mymatrix of newlist row col cell count {
	
		mat colnames `mymatrix' = `a' "Total"
	
	}

}





end

exit

