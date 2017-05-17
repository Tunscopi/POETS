#**********************************************************************************************
# POETSDataParser.py
# -- Currently in Development -- 
# Purpose: This serves to parse collected .xls excel data files for accelerated Data Analysis
# 
# Features: Reads in data from .xls files 
#           Writes data to .xls files
#           Allows for quick visualization of data with plots
#           Provide other quick handy information about .xls file eg. no. of rows, cols etc. 
#          
# 
# Date:   TBD
#**********************************************************************************************


import xlrd
mybook = xlrd.open_workbook("Data/ScanRawData.xls")

print("***************************************************************************************")
print("The no. of worksheets is {0}".format(mybook.nsheets))
print("Worksheet name(s): {0}".format(mybook.sheet_names()))
sh = mybook.sheet_by_index(0)
print("Sheet:{0}  rows: {1}  cols: {2}".format(sh.name, sh.nrows, sh.ncols))
print("Inductor Obj. Temp is {0}".format(sh.cell_value(rowx=29-1, colx=1)))
for rowx in range(sh.nrows):
    print(sh.row(rowx))

print("***************************************************************************************")
print("")

