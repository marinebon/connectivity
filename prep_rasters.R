library(sp)
library(rgdal)
library(raster)
library(tidyverse)
library(stringr)
library(knitr)
library(mapview)
library(marmap) # devtools::install_github('ericpante/marmap')

dir_data = switch(
  R.utils::System$getUsername(),
  bbest = '/Volumes/Best HD/mbon_data_big',
  sgad  = 'P:/habitats')

dir_hab = dir_data
dir_tmp = file.path(dir_hab, 'tmp')
dir.create(dir_tmp, showWarnings=F)
dir.create(dir_hab, showWarnings=F)


tif_all  = file.path(dir_data, 'hab_id.tif')
csv_all  = file.path(dir_data, 'hab_id.csv')
csv_sources = file.path('hab_sources.csv')

# paths & vars
tif_m_g  = 'P:/habitats/ocean_mask.tif'
gdb      = 'H:/MBON/study_area.gdb'
regions  = c('southeast', 'southwest', 'channelislands')

# read global water mask raster
r_m_g = raster(tif_m_g)
fact_100km = 100000 %/% xres(r_m_g)

for (rgn in regions){ # rgn = 'channelislands'
  
  # set region specific paths
  tif_m     = sprintf('P:/habitats/%s-1km_mask.tif'   , rgn)
  tif_p     = sprintf('P:/habitats/%s-1km_patchid.tif', rgn)
  tif_c     = sprintf('P:/habitats/%s-1km_percentcover.tif', rgn)
  tif_m_100km = sprintf('P:/habitats/%s-100km_mask.tif'   , rgn)
  tif_p_100km = sprintf('P:/habitats/%s-100km_patchid.tif', rgn)
  tif_c_100km = sprintf('P:/habitats/%s-100km_percentcover.tif', rgn)

  # read in buffer in same projection as global water mask (Mollweide)
  buf = readOGR(gdb, sprintf('%s_buf_mol', rgn))
  #buf = readOGR(gdb, 'channelislands') # TODO: resolve difference w/ other regions

  # generate Water mask raster & patch cover raster
  r_m = crop(r_m_g, buf) %>% # water = 1; land = 0
    trim() %>%
    mask(buf)
  r_m[r_m==0] = NA # convert land to NA for single mask value
  as.logical(r_m, filename=tif_m, overwrite=T)

  # generate patch IDs raster
  #r_p = setValues(r_m, 1:ncell(r_m)) %>%
  #  mask(r_m)
  r_p = r_m
  n_1 = sum(!is.na(getValues(r_p)))
  r_p[!is.na(r_p)] = 1:n_1 # plot(r_p)
  
  setValues(r_m, 1:ncell(r_m)) %>%
    mask(r_m)
  as.integer(r_p, filename=tif_p, overwrite=T)
  
  # generate percent cover raster
  r_c = r_m
  r_c[r_c==1] = 1.0
  writeRaster(r_c, tif_c, overwrite=T)
  
  # reduce resolution, ie increase pixel size to 9 km
  r_m_100km = aggregate(r_m, fact_100km)
  as.logical(r_m_100km, filename=tif_m_100km, overwrite=T)
  
  # generate patch IDs raster
  r_p_100km = setValues(r_m_100km, 1:ncell(r_m_100km)) %>%
    mask(r_m_100km)
  as.integer(r_p_100km, filename=tif_p_100km, overwrite=T)

  # generate percent cover raster
  r_c_100km = r_m_100km
  r_c_100km[r_c_100km==1] = 1.0
  writeRaster(r_c_100km, tif_c_100km, overwrite=T)
