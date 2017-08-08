# load packages
library(sp)
library(rgdal)
library(raster)
library(tidyverse)
library(stringr)
library(knitr)
library(mapview)
library(marmap) # devtools::install_github('ericpante/marmap')

# setup working directory
dir_data = switch(
  R.utils::System$getUsername(),
  bbest = '/Volumes/Best HD/mbon_data_big',
  sgad  = 'P:/habitats')

# setup dirs
dir_hab = dir_data
dir_tmp = file.path(dir_hab, 'tmp')
dir.create(dir_tmp, showWarnings=F)
dir.create(dir_hab, showWarnings=F)

# paths & vars
tif_all     = file.path(dir_data, 'hab_id.tif')
csv_all     = file.path(dir_data, 'hab_id.csv')
csv_sources = file.path('hab_sources.csv')
tif_m_g     = file.path(dir_data, 'ocean_mask.tif')
gdb         = 'H:/MBON/study_area.gdb'
# regions     = c('southeast', 'southwest', 'channelislands')
regions     = c('fknms_300buf','mbnms_300buf')
redo        = FALSE

# read global water mask raster
r_m_g = raster(tif_m_g)

for (rgn in regions){ # rgn = 'channelislands'
  
  # set region specific paths
  tif_m     = sprintf('P:/habitats/%s-1km_mask.tif'   , rgn)
  tif_p     = sprintf('P:/habitats/%s-1km_patchid.tif', rgn)
  tif_c     = sprintf('P:/habitats/%s-1km_percentcover.tif', rgn)
  
  # water mask: logical (16-bit signed integer)
  if (!file.exists(tif_m)){
    
    # read in buffer in same projection as global water mask (Mollweide)
    buf = readOGR(gdb, sprintf('%s_mol', rgn))
    #buf = readOGR(gdb, 'channelislands') # TODO: resolve difference w/ other regions
    
    # generate Water mask raster & patch cover raster
    r_m = crop(r_m_g, buf) %>% # water = 1; land = 0
      trim() %>%
      mask(buf)
    r_m[r_m==0] = NA # convert land to NA for single mask value
    as.logical(r_m, filename=tif_m, overwrite=T)
  } else {
    r_m = raster(tif_m)
  }
  
  # patchid: integer (32-bit signed integer)
  if (!file.exists(tif_p)){

    # generate patch IDs raster
    r_p = r_m
    r_p[!is.na(r_p)] = 1:sum(!is.na(getValues(r_p))) # plot(r_p)
    as.integer(r_p, filename=tif_p, overwrite=T)
    
  } else {
    r_m = raster(tif_p)
  }
  
  # percentcover: floating (64-bit double precision)
  if (!file.exists(tif_c)){
    
    # generate percent cover raster
    r_c = r_m
    r_c[r_c==1] = 1.0
    writeRaster(r_c, tif_c, overwrite=T)
  }
}

agg_rasters = function(tif_m_1km, km_factor=9){
  # tif_m should end with: "-1km_mask.tif"
  #
  # tif_m_in = 'P:/habitats/channelislands_700buf-1km_mask.tif'; km_factor=100
  # tif_m_in = 'P:/habitats/channelislands-1km_mask.tif'; km_factor=100

  pfx = str_replace(tif_m_1km, '(.*)-1km_mask.tif', '\\1')
  tif_m = sprintf('%s-%dkm_mask.tif'        , pfx, km_factor)
  tif_p = sprintf('%s-%dkm_patchid.tif'     , pfx, km_factor)
  tif_c = sprintf('%s-%dkm_percentcover.tif', pfx, km_factor)

  # reduce resolution, ie increase pixel size to 9 km
  r_m_1km = raster(tif_m_1km)
  km_factor_int = km_factor*1000 %/% xres(r_m_1km)
  r_m = aggregate(r_m_1km, km_factor_int)
  as.logical(r_m, filename=tif_m, overwrite=T)

  # generate patch IDs raster
  r_p = r_m
  r_p[!is.na(r_p)] = 1:sum(!is.na(getValues(r_p))) # plot(r_p)
  as.integer(r_p, filename=tif_p, overwrite=T)
  p_max = cellStats(r_p, 'max'); if (p_max > 65534) stop(sprintf('DOH! Max(patchid)==%d > 65,534, ie too much of a BIG BOY!', p_max))

  # generate percent cover raster
  r_c = r_m
  r_c[r_c==1] = 1.0
  writeRaster(r_c, tif_c, overwrite=T)
  
}

# agg_rasters('P:/habitats/fknms_700buf-1km_mask.tif', km_factor=9)
# agg_rasters('P:/habitats/mbnms_700buf-1km_mask.tif', km_factor=9)
# agg_rasters('P:/habitats/fknms_700buf-1km_mask.tif', km_factor=18)
# agg_rasters('P:/habitats/mbnms_700buf-1km_mask.tif', km_factor=18)
# agg_rasters('P:/habitats/fknms_700buf-1km_mask.tif', km_factor=27)
# agg_rasters('P:/habitats/mbnms_700buf-1km_mask.tif', km_factor=27)
# agg_rasters('P:/habitats/fknms_700buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/mbnms_700buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/fknms_500buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/mbnms_500buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/fknms_500buf-1km_mask.tif', km_factor=27)
# agg_rasters('P:/habitats/mbnms_500buf-1km_mask.tif', km_factor=27)
# agg_rasters('P:/habitats/fknms_500buf-1km_mask.tif', km_factor=36)
# agg_rasters('P:/habitats/mbnms_500buf-1km_mask.tif', km_factor=36)

agg_rasters('P:/habitats/fknms_300buf-1km_mask.tif', km_factor=27)
agg_rasters('P:/habitats/mbnms_300buf-1km_mask.tif', km_factor=27)

 
#Southwest and southeast rasters----
#agg_rasters('P:/habitats/channelislands-1km_mask.tif', km_factor=100)
#agg_rasters('P:/habitats/southwest-1km_mask.tif', km_factor=9)
#agg_rasters('P:/habitats/southeast-1km_mask.tif', km_factor=9)
#agg_rasters('P:/habitats/southwest_700buf-1km_mask.tif', km_factor=9)
#agg_rasters('P:/habitats/southeast_700buf-1km_mask.tif', km_factor=9)
#agg_rasters('P:/habitats/southeast_700buf-1km_mask.tif', km_factor=18)
#agg_rasters('P:/habitats/southwest_700buf-1km_mask.tif', km_factor=18)
#agg_rasters('P:/habitats/southwest-1km_mask.tif', km_factor=27)
#agg_rasters('P:/habitats/southeast-1km_mask.tif', km_factor=27)
#agg_rasters('P:/habitats/southwest-1km_mask.tif', km_factor=36)
#agg_rasters('P:/habitats/southeast-1km_mask.tif', km_factor=36)
#agg_rasters('P:/habitats/southwest-1km_mask.tif', km_factor=45) 
#agg_rasters('P:/habitats/southeast-1km_mask.tif', km_factor=45)

# agg_rasters('P:/habitats/southeast_700buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/southwest_700buf-1km_mask.tif', km_factor=45)
# agg_rasters('P:/habitats/southeast_700buf-1km_mask.tif', km_factor=54)
# agg_rasters('P:/habitats/southwest_700buf-1km_mask.tif', km_factor=54)
