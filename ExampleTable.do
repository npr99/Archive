version 12.1
clear
set more off
* From http://repec.org/bocode/e/estout/advanced.html#advanced501
sysuse auto

eststo: quietly reg weight mpg
eststo: quietly reg weight mpg foreign
eststo: quietly reg price weight mpg
eststo: quietly reg price weight mpg foreign
esttab using "C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\DissertationLaTexDoc\tables\example.tex", booktabs label replace ///
title(Two models one table) ///
mgroups(A B, pattern(1 0 1 0)                   ///
prefix(\multicolumn{@span}{c}{) suffix(})   ///
span erepeat(\cmidrule(lr){@span}))         ///
alignment(D{.}{.}{-1}) nonumber
eststo clear
