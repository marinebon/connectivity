library(tidyverse)
library(shiny)
library(sf)
library(rgdal)
library(raster)
library(leaflet)
library(geojsonio)

#r_pid = raster(
dir_results = 'P:/mbnms_2009/10day_300buf-27km/01_25_2009_mbnms_10day_300buf-27km_results'

r_pid = raster('P:/habitats/mbnms_300buf-27km_patchid.tif')
#r_pid
#plot(r_pid)

study_sf = readOGR('H:/MBON/study_area.gdb','mbnms_300buf_mol') %>%
  st_as_sf()

server <- function(input, output, session) {

  output$map <- renderLeaflet({
    
    leaflet() %>%
      addProviderTiles(providers$Stamen.TonerLite) %>%
      addRasterImage(
        r_pid, group='PatchID', opacity=0.3) %>%
      addDrawToolbar(
        targetGroup='Draw', #opacity=0.5, fillOpacity=0.3, 
        polylineOptions=F, markerOptions=F, singleFeature=T,
        editOptions = editToolbarOptions(
          selectedPathOptions = selectedPathOptions()))  %>%
      addLayersControl(
        overlayGroups = c('Draw','PatchID'), 
        options = layersControlOptions(collapsed=T))

  })
  

  observeEvent(input$map_draw_stop,{
    
    ply = input$map_draw_new_feature %>%
      as.json() %>% geojson_sp()
    # ply = read_sf('tmp_ply.geojson') %>% as('Spatial')
    #browser()
    
    r_ply = raster::extract(r_pid, ply, cellnumbers=T)[[1]]
    i_r = r_ply[,'cell']
    sel_patchids = r_ply[,'value']
    
    r_hi = r_pid
    r_hi[setdiff(1:ncell(r_pid), i_r)] = NA

    conn_lns = readOGR(file.path(dir_results, 'output.gdb'), 'Connectivity', verbose=F)
    
    # Import first...
    if (input$sel_dir == 'Import'){
      
      conn_tbl = conn_lns@data %>%
        as_tibble() %>%
        filter(ToPatchID %in% sel_patchids) %>%
        group_by(FromPatchID) %>%
        summarize(quantity = sum(Quantity)) %>%
        ungroup() %>%
        mutate(percent = quantity / sum(quantity) * 100) %>%
        arrange(desc(percent)) %>%
        select(patchid=FromPatchID, percent)
      
    } else {
      
      conn_tbl = conn_lns@data %>%
        as_tibble() %>%
        filter(FromPatchID %in% sel_patchids) %>%
        group_by(ToPatchID) %>%
        summarize(quantity = sum(Quantity)) %>%
        ungroup() %>%
        mutate(percent = quantity / sum(quantity) * 100) %>%
        arrange(desc(percent)) %>%
        select(patchid=ToPatchID, percent)
    }
    
    r_pct = subs(r_pid, conn_tbl)
    #plot(r_pct)
    
    pal = colorNumeric('Spectral', values(r_pct), reverse=T)
    
    leafletProxy('map') %>% 
      clearControls() %>%         # clear legend
      clearGroup('Selected') %>%  # clear previous selected pixels
      addRasterImage(
        r_pct, group='Selected', colors=pal, opacity=0.8) %>%
      addLegend(
        pal = pal, values = values(r), title = "% Larvae",
        labFormat = labelFormat(
          prefix = '(', suffix = ')%', between = ', ',
          transform = function(x) 100 * x))
    
  })
}

