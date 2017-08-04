library(shiny)
library(sf)
library(rgdal)
library(raster)
library(leaflet)


#r_pid = raster('P:/mbnms_2009/10day_300buf-27km/01_25_2009_mbnms_10day_300buf-27km_simulation/PatchData/patch_ids')
r_pid = raster('P:/habitats/mbnms_300buf-27km_patchid.tif')
#r_pid
#plot(r_pid)

study_sf = readOGR('H:/MBON/study_area.gdb','mbnms_300buf_mol') %>%
  st_as_sf()

server <- function(input, output, session) {
  drawn <- callModule(editMod, "editmap", mapview(study_sf, alpha=0.1, alpha.regions=0.2)@map)
  
  output$mymap <- renderLeaflet({
    
    req(drawn()$finished)
    
    ply = drawn()$finished
    
    #browser()
    # setwd('conn')
    #write_sf(ply, 'tmp_ply.geojson')
    #ply = read_sf('tmp_ply.geojson')
    
    i_r_ply = extract(r_pid, ply %>% as('Spatial'), cellnumbers=T)[[1]][,'cell']
    
    r_hi = r_pid
    r_hi[setdiff(1:ncell(r_pid), i_r_ply)] = NA
    
    # mapview(r_pid, alpha.regions = 0.3) + 
    #   mapview(r_hi, alpha.regions = 0.8) +
    #   mapview(ply)
    
    
    (mapview(r_pid, alpha.regions = 0.3) + 
        mapview(r_hi, alpha.regions = 0.8) +
        mapview(drawn()$finished))@map

  })
}

