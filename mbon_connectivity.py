# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# mget_script.py
# Created on: 2017-06-22
# Description: MBON MGET Model Runs
#To run from command terminal:
# Start > Run > cmd
#   P: & cd P:\connectivity\ & C:\Python27\ArcGIS10.4\python.exe mbon_connectivity.py runs_todo.csv
# ---------------------------------------------------------------------------

# Import arcpy module
import arcgisscripting, shutil, os, csv, sys

# get input arguments
runs_csv  = "P:\\connectivity\\runs_todo.csv"
cache_dir = "P:\\MGET_cache"

gp = arcgisscripting.create()
gp.AddToolbox('C:\\Program Files\\GeoEco\\ArcGISToolbox\\Marine Geospatial Ecology Tools.tbx', 'GeoEco')

# read in csv with runs per row and variables per column
csv_file = open(runs_csv, 'r')
runs = csv.DictReader(csv_file)

# iterate over runs
for run in runs:
	
	# assign variables
	for var in run.keys():
		globals()[var] = run[var]

	# set region-specific paths	
	watermask_tif    = "P:\\habitats\\{region}{habitatsuffix}_mask.tif".format(region=rgn, habitatsuffix=hab_sfx)
	patchid_tif      = "P:\\habitats\\{region}{habitatsuffix}_patchid.tif".format(region=rgn, habitatsuffix=hab_sfx)
	pctcover_tif     = "P:\\habitats\\{region}{habitatsuffix}_percentcover.tif".format(region=rgn, habitatsuffix=hab_sfx)
	simulation_dir 	 = "P:\\{region}_{year}\\{prefix}_{region}_{suffix}_simulation".format(year=yr, prefix=pfx, region=rgn, suffix=sfx)
	results_dir      = "P:\\{region}_{year}\\{prefix}_{region}_{suffix}_results".format(year=yr, prefix=pfx, region=rgn, suffix=sfx)
	print os.path.basename(simulation_dir)

	# Process: Create Larval Dispersal Simulation From ArcGIS Rasters
	print '  LarvalDispersalCreateSimulationFromArcGISRasters_GeoEco ->', simulation_dir
	if os.path.isdir(simulation_dir):
		shutil.rmtree(simulation_dir)
	gp.LarvalDispersalCreateSimulationFromArcGISRasters_GeoEco(simulation_dir, patchid_tif, pctcover_tif, watermask_tif, "false")

	# Process: Load HYCOM GLBa0.08 Currents Into Larval Dispersal Simulation
	print '  LarvalDispersalLoadHYCOMGLBa0084DEquatorialCurrentsIntoSimulation_GeoEco ->', cache_dir
	endDate = datetime.datetime.strptime(startDate, "%m/%d/%Y") + datetime.timedelta(days=int(durationDays))	
	gp.LarvalDispersalLoadHYCOMGLBa0084DEquatorialCurrentsIntoSimulation_GeoEco(simulation_dir, "startDate", "endDate", "0", "false", "Meters", "false", "CUBIC", "Del2a", "60", "120", "cache_dir")

	# Process: Run Larval Dispersal Simulation (2012 Algorithm)
	print '  LarvalDispersalRunSimulation2012_GeoEco ->', results_dir
	if os.path.isdir(results_dir):
		shutil.rmtree(results_dir)
	os.mkdir(results_dir)
	gp.LarvalDispersalRunSimulation2012_GeoEco(simulation_dir, results_dir, startDate, "durationDays", ".5", "24", "", "", "0.8", "false", "", "", "", "50")

	# Process: Visualize Larval Dispersal Simulation Results (2012 Algorithm)
	print '  LarvalDispersalVisualizeResults2012_GeoEco ->', results_dir
	gp.LarvalDispersalVisualizeResults2012_GeoEco(simulation_dir, results_dir, "output.gdb", "", "A", "true", "0.00001", "false", "true", "0.00001", "Quantity")

csv_file.close()