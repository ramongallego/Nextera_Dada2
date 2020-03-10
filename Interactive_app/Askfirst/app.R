#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Preview of the MiSeq run"),

    # Sidebar with a slider input for number of bins 
    fluidRow(
       # sidebarPanel(
            column(width = 4, 
                   fileInput(inputId = "Fastq_fwd",
                                        label = "Select a few Forward fastqs",
                                        multiple = T )),
            column(width = 8,
                   plotOutput("qPlot_Fwd", click = "fwd_click"))),
    fluidRow(
        # sidebarPanel(
        column(width = 4, 
               fileInput(inputId = "Fastq_rev",
                         label = "Select a few Reverse fastqs",
                         multiple = T )),
        column(width = 8,
               plotOutput("qPlot_Rev", click = "rev_click"))),
    fluidRow(
        column(width = 1,
               verbatimTextOutput("info_fwd")),
        column(width = 4,
               numericInput(inputId = "trimming.length.Read1", 
                            label = "Trimming length forward reads",
                            value = 200)),
        column(width = 1,
               verbatimTextOutput("info_rev")),
        
        column(width = 4,
               numericInput(inputId = "trimming.length.Read2", 
                            label = "Trimming length reverse reads",
                            value = 200))
    ),
    fluidRow(
        column(width = 3, checkboxInput(inputId = "Hash",
                                        label = "Use hashing")),
        column(width = 3, fileInput(inputId = "metadata",
                                    label = "metadata file")),
        column(width = 3, textInput(inputId = "outputfolder",
                                    label = "output folder")),
        column(width = 3, downloadButton("report","Generate Report"))
    )
        # 
        #     plotOutput("qPlot_Fwd"))
        #    # plotOutput("qPlot_Fwd"),
        #     fileInput(inputId = "Fastq_rev",
        #               label = "Select a few Reverse fastqs",
        #               multiple = T ),
        #     
        # #),
        # 
        # # Show a plot of the generated distribution
        # #mainPanel(
        #    plotOutput("qPlot_Fwd"),
        #    plotOutput("qplot_Rev")
        #)
    )
# )

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$qPlot_Fwd <- renderPlot({
        inFile <- input$Fastq_fwd
        dada2::plotQualityProfile(inFile$datapath) +
            ggplot2::geom_hline(yintercept = 30, color = "red") +
            ggplot2::labs(title = "Average quality per cycle -  Forward Files",
                          subtitle = "Choose a trimming length accordingly\n hint = target Q 30")
        
        # # generate bins based on input$bins from ui.R
        # x    <- faithful[, 2]
        # bins <- seq(min(x), max(x), length.out = input$bins + 1)
        # 
        # # draw the histogram with the specified number of bins
        # hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
    output$qPlot_Rev <- renderPlot({
        inFile2 <- input$Fastq_rev
        dada2::plotQualityProfile(inFile2$datapath) +
            ggplot2::geom_hline(yintercept = 30, color = "red") +
            ggplot2::labs(title = "Average quality per cycle -  Reverse Files",
                          subtitle = "Choose a trimming length accordingly\n hint = target Q 30")

        # # generate bins based on input$bins from ui.R
        # x    <- faithful[, 2]
        # bins <- seq(min(x), max(x), length.out = input$bins + 1)
        # 
        # # draw the histogram with the specified number of bins
        # hist(x, breaks = bins, col = 'darkgray', border = 'white')
     })
    output$info_fwd <- renderText({ round(input$fwd_click$x,0)})
    
    output$info_rev <- renderText({ round(input$rev_click$x,0)})
    
    output$report <- downloadHandler(
        
        filename = "analysis.params.csv",
        content = function(file){write_csv(tibble(Folder = (dirname(input$Fastq_rev$name)),
                                                  metadata = input$metadata,
                                                  read.length1 = input$trimming.length.Read1,
                                                  read.length2 = input$trimming.length.Read2), file)
        # content = function(file) {
        #     tibble(Input.fastqs  = unique(dirname(input$Fastq_rev)),
        #            output.folder = input$outputfolder) %>% 
        #         
        #         write_csv(file)
        }
    )
    #     input$go, {input$outputfolder
    #         
    #         tibble(Input.fastqs  = unique(dirname(input$Fastq_rev)),
    #                output.folder = input$outputfolder) %>% 
    #             
    #             write_csv(file.path(input$outputfolder, "analysis.params.csv"))
    #         
  
   
        
        
        # render("r/dada2.Rmd", output_file = paste0(output.folder,"/dada2_report.html"),
        #        params = list(folder = output.folder,
        #                      fastqs = fastq.folder,
        #                      hash = hashing,
        #                      original = source,
        #                      cont = continuing))
        
      
}
# Run the application 
shinyApp(ui = ui, server = server)
