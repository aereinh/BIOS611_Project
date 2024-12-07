library(shiny)
library(shinyjs)
library(ggplot2)
library(reshape2)
library(torchaudio)
library(base64enc)

mel_to_hz <- function(mel) {
  700 * (10^(mel / 2595) - 1)
}

hz_to_mel <- function(hz) {
  2595 * log10(1 + hz / 700)
}

generate_hertz_ticks <- function(f_min, f_max, num_ticks = 10) {
  # Generate evenly spaced round numbers between f_min and f_max
  pretty(seq(f_min, f_max, length.out = num_ticks))
}

vis_mel_spect <- function(filepath, n_fft = 2^13, n_mels = 128, time_range = c(0,30), freq_range = NULL) {
  waveform <- torchaudio_load(filepath)
  waveform_tensor <- transform_to_tensor(waveform)
  sample_rate <- waveform_tensor[[2]]
  hop_length <- n_fft / 2
  if (nrow(waveform_tensor[[1]]) > 1) {
    waveform_tensor[[1]] <- waveform_tensor[[1]][1,]$unsqueeze(1)
  }
  if (!is.null(time_range)) {
    n_samples <- ncol(waveform)
    start_sample <- max(1, time_range[1]*sample_rate)
    end_sample <- min(n_samples, time_range[2]*sample_rate)
    waveform_tensor[[1]] <- waveform_tensor[[1]][,start_sample:end_sample]
  }
  f_min = 0
  f_max = sample_rate/2
  if (!is.null(freq_range)) {
    f_min = max(0, freq_range[1])
    f_max = min(sample_rate/2, freq_range[2])
  }
  
  mel_spectrogram <- torchaudio::transform_mel_spectrogram(sample_rate = sample_rate,
                                                           n_fft = n_fft, n_mels = n_mels,
                                                           f_min = f_min, f_max = f_max)
  mel_spec_tensor <- mel_spectrogram(waveform_tensor[[1]])
  mel_spec_matrix <- as.matrix(mel_spec_tensor$squeeze()$to(device = "cpu"))
  mel_spec_matrix <- log1p(mel_spec_matrix)
  
  mel_spec_df <- melt(mel_spec_matrix)
  colnames(mel_spec_df) <- c("Frequency", "Time", "Amplitude")
  
  #mel_spec_df$Frequency <- mel_spec_df$Frequency * (f_max-f_min)/n_mels + f_min
  #mel_bins <- seq(0, n_mels - 1)
  #mel_frequencies <- mel_to_hz(seq(0, n_mels - 1) * (f_max - f_min) / n_mels + f_min)
  #mel_spec_df$Frequency <- mel_frequencies[mel_spec_df$Mel]

  mel_spec_df$Time <- mel_spec_df$Time * hop_length / sample_rate + ifelse(is.null(time_range), 0, time_range[1])
  
  hertz_ticks <- generate_hertz_ticks(f_min, f_max, num_ticks = 10)
  mel_bins <- (hz_to_mel(hertz_ticks) - hz_to_mel(f_min))/(hz_to_mel(f_max)-hz_to_mel(f_min))*(n_mels-1)
  
  plt <- ggplot(mel_spec_df, aes(x = Time, y = Frequency, fill = Amplitude)) +
    geom_tile() +
    scale_y_continuous(breaks = mel_bins,
                       labels = round(hertz_ticks,0))+
    scale_fill_viridis_c() +
    labs(title = "Mel Spectrogram", x = "Time (s)", y = "Frequency (Hz)") +
    theme_minimal()
  plt
}

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Interactive Mel Spectrogram Viewer"),
  sidebarLayout(
    sidebarPanel(
      fileInput("audio_file", "Upload Audio File (.wav)", accept = ".wav"),
      sliderInput("n_fft_power", "FFT Window Length (2^x):",
                  min = 8, max = 20, value = 13, step = 1),
      sliderInput("n_mels", "Number of Mel Bands (n_mels):", 
                  min = 16, max = 512, value = 256, step = 32),
      sliderInput("time_range", "Time Range (seconds):", 
                  min = 0, max = 30, value = c(0, 30), step = 1),
      sliderInput("freq_range", "Frequency Range (Hz):", 
                  min = 0, max = 10000, value = c(0, 4000), step = 100)
    ),
    mainPanel(
      plotOutput("spectrogram_plot"),
      div(id = "audio_player_placeholder")
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$audio_file, {
    req(input$audio_file)  # Ensure a file is uploaded
    
    # Remove any existing audio player
    removeUI(selector = "#audio_player", immediate = TRUE)
    
    base64 <- dataURI(file = input$audio_file$datapath, mime = "audio/wav")
    
    # Dynamically insert the audio player below the plot
    insertUI(
      selector = "#audio_player_placeholder",
      where = "afterEnd",
      ui = tags$audio(
        id = "audio_player",  # Ensure the player has visible controls
        src = base64,
        type = "audio/wav",
        controls = "controls",
        style = "width: 100%; margin-top: 20px;"
      )
    )
    
    runjs("
      const audio = document.getElementById('audio_player');
    ")
  })
  
  output$spectrogram_plot <- renderPlot({
    req(input$audio_file)  # Ensure a file is uploaded
    
    # Get file path and user inputs
    filepath <- input$audio_file$datapath
    n_fft <- 2^input$n_fft_power
    n_mels <- input$n_mels
    time_range <- input$time_range
    freq_range <- input$freq_range
    
    # Generate and return the spectrogram
    vis_mel_spect(filepath, n_fft = n_fft, n_mels = n_mels, time_range = time_range, freq_range = freq_range)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
