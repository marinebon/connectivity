# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# mget_script.py
# Created on: 2017-06-22
# Description: MBON MGET Model Runs
#To run from command terminal:
# Start > Run > cmd
#   P: & cd P:\connectivity\ & C:\Python27\ArcGIS10.4\python.exe mbon_connectivity.py runs_todo_xxxx.csv
# ---------------------------------------------------------------------------

# Import arcpy module
#import arcgisscripting as ap, shutil, os, csv, sys
import arcpy as ap, shutil, os, csv, sys

# get input arguments
runs_csv = sys.argv[1] #"P:\\connectivity\\runs_todo.csv"
cache_dir = "P:\\MGET_cache"

#gp = arcgisscripting.create()
ap.AddToolbox('C:\\Program Files\\GeoEco\\ArcGISToolbox\\Marine Geospatial Ecology Tools.tbx', 'GeoEco')

# read in csv with runs per row and variables per column
csv_file = open(runs_csv, 'r')
runs = csv.DictReader(csv_file)

# iterate over runs
for run in runs: # run = runs.next()

	if run['do'] == 'FALSE':
		continue

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
	print '\n**LarvalDispersalCreateSimulationFromArcGISRasters**\n'
	# http://code.nicholas.duke.edu/projects/mget/export/1452/MGET/Trunk/PythonPackage/dist/TracOnlineDocumentation/Documentation/ArcGISReference/LarvalDispersal.CreateSimulationFromArcGISRasters.html
	if os.path.isdir(simulation_dir):
		shutil.rmtree(simulation_dir, ignore_errors=True)	
	ap.LarvalDispersalCreateSimulationFromArcGISRasters_GeoEco(
		simulation_dir, # simulationDirectory
		patchid_tif,    # patchIDsRaster
		pctcover_tif,   # patchCoverRaster
		watermask_tif,  # waterMaskRaster
		False)          # crosses180

	# override coordinate system to get past error:
	#   ValueError: band 1 of GDAL dataset "P:\southwest_2010\10_7_2010_southwest_10day-45km_simulation\PatchData\water_mask" has a different coordinate system than larval density matrix, so it cannot be used as a mask.
	print '\n**DefineProjection**\n'
	coord_sys = arcpy.Describe('%s/PatchData/water_mask' % simulation_dir).spatialReference
	ap.DefineProjection_management('%s/PatchData/patch_ids' % simulation_dir, coord_sys)
	
	# Process: Load HYCOM GLBa0.08 Currents Into Larval Dispersal Simulation
	# http://code.nicholas.duke.edu/projects/mget/export/1452/MGET/Trunk/PythonPackage/dist/TracOnlineDocumentation/Documentation/ArcGISReference/LarvalDispersal.LoadHYCOMGLBa0084DEquatorialCurrentsIntoSimulation.html
	# TODO: interpolationMethod='Del2b' #If you receive and OUT OF MEMORY error when utilizing this parameter, try switching to the Del2b or Del2c algorithm
	print '\n**LarvalDispersalLoadHYCOMGLBa0084DEquatorialCurrentsIntoSimulation**\n'
	endDate = datetime.datetime.strptime(startDate, "%m/%d/%Y") + datetime.timedelta(days=int(durationDays))
	ap.LarvalDispersalLoadHYCOMGLBa0084DEquatorialCurrentsIntoSimulation_GeoEco(
		simulation_dir, # simulationDirectory
		startDate,      # startDate
		endDate,        # endDate
		0,              # depth		
		'',             # rotationOffset
		'',             # linearUnit
		False,          # extendYExtent
		'CUBIC',        # resamplingTechnique
		'Del2a',        # interpolationMethod
		60,             # timeout
		120,            # maxRetryTime
		cache_dir)      # cacheDirectory

	# Process: Run Larval Dispersal Simulation (2012 Algorithm)
	# http://code.nicholas.duke.edu/projects/mget/export/1452/MGET/Trunk/PythonPackage/dist/TracOnlineDocumentation/Documentation/ArcGISReference/LarvalDispersal.RunSimulation2012.html
	# TODO a=?; b=? # Competency gamma a; Competency gamma b
	print '\n**LarvalDispersalRunSimulation2012**\n'
	if os.path.isdir(results_dir):
		shutil.rmtree(results_dir, ignore_errors=True)
	os.mkdir(results_dir)
	ap.LarvalDispersalRunSimulation2012_GeoEco(
		simulation_dir,    # simulationDirectory
		results_dir,       # resultsDirectory
		startDate,         # startDate
		int(durationDays), # duration
		1,                 # simulationTimeStep in hours
		24,                # summarizationPeriod
		'',                # a # Competency gamma a
		'',                # b # Competency gamma b
		'',                # settlementRate
		False,             # useSensoryZone		
		'',                # sourcePatchIDs
		'',                # destPatchIDs
		'',                # excludePatchIDs
		50)                # diffusivity

	# Process: Visualize Larval Dispersal Simulation Results (2012 Algorithm)
	# http://code.nicholas.duke.edu/projects/mget/export/1452/MGET/Trunk/PythonPackage/dist/TracOnlineDocumentation/Documentation/ArcGISReference/LarvalDispersal.VisualizeResults2012.html
	# TODO: mortalityRate=durationDays*0.1; mortalityMethod='A' # eg target 10% at end of PLD
	# TODO: minimumDispersalType='Probability' OR minimumDispersalType='Quantity'
	gdb = '%s/output.gdb' % results_dir
	if os.path.isdir(gdb):
		shutil.rmtree(gdb, ignore_errors=True)
	print '\n**LarvalDispersalVisualizeResults2012**\n'
	ap.LarvalDispersalVisualizeResults2012_GeoEco(
		simulation_dir, # simulationDirectory
		results_dir,    # resultsDirectory
		'output.gdb',   # outputGDBName
		'',             # mortalityRate
		'',             # mortalityMethod
		True,           # createDensityRasters
		0.00001,        # minimumDensity
		False,          # useCompetencyForDensityRasters
		True,           # createConnectionsFeatureClass
		0.00001,        # minimumDispersal
		'Quantity')     # minimumDispersalType

csv_file.close()