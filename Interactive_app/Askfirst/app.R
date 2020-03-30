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
               verbatimTextOutput("info_rev",placeholder = T)),
        
        column(width = 4,
               numericInput(inputId = "trimming.length.Read2", 
                            label = "Trimming length reverse reads",
                            value = 200))
    ),
    fluidRow(
        column(width = 2, checkboxInput(inputId = "Hash",
                                        label = "Use hashing")),
        column(width = 3, fileInput(inputId = "metadata",
                                    label = "metadata file")),
        column(width = 2, textInput(inputId = "outputfolder",
                                    label = "output folder")),
        column(width = 2, downloadButton("report","Generate Report")),
        
        column(width = 2, downloadButton("cutadapt.wrap", "Remove primers"))
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
        content = function(file){write_csv(tibble(Folder = (unique(dirname(input$Fastq_rev$name))),
                                                  metadata = input$metadata,
                                                  read.length1 = input$trimming.length.Read1,
                                                  read.length2 = input$trimming.length.Read2,
                                                  Hash         = input$Hash), file)
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
    output$cutadapt.wrap <- downloadHandler(
      # For PDF output, change this to "report.pdf"
      filename = "report.html",
      content = function(file) {
        # Copy the report file to a temporary directory before processing it, in
        # case we don't have write permissions to the current working dir (which
        # can happen when deployed).
        # tempReport <- file.path(tempdir(), "report.Rmd")
        # file.copy("../scripts/cutadapt.wrapper.Rmd", tempReport, overwrite = TRUE)
        dir.create(input$outputfolder)
        write_csv (read_csv(input$metadata$datapath),
                   path = file.path(input$outputfolder, "metadata.csv") )
        # Set up parameters to pass to Rmd document
        params <-  list(folder = unique(normalizePath(dirname(input$Fastq_rev$name))),
                        metadata = file.path(normalizePath(input$outputfolder), "metadata.csv"),
                        outputfolder = input$outputfolder )
                                     #                      hash = hashing,
                                     #                      original = source,
                                     #                      cont = continuing))
        
        
        # Knit the document, passing in the `params` list, and eval it in a
        # child of the global environment (this isolates the code in the document
        # from the code in this app).
        rmarkdown::render("../../scripts/cutadapt.wrapper.Rmd",
                          output_file = file,
                          params = params,
                          envir = new.env(parent = globalenv()))
        
      }
    
    )
   
        
        
        # 
        
      
}
# Run the application 
shinyApp(ui = ui, server = server)
