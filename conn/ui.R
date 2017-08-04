shinyUI(fluidPage(
  
  titlePanel("Larval Connectivity Explorer"),
  
  sidebarLayout(
    
    sidebarPanel(
      editModUI("editmap"),
      p(),
      actionButton("update", "Update")),
    
    mainPanel(
      leafletOutput("mymap")))

))
