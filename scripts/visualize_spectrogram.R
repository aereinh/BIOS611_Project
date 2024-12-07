library(ggplot2)
library(reshape2)
library(torchaudio)

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

wav_files <- list.files('data/genres_original/', recursive = T, full.names = T)
genres <- basename(dirname(wav_files))

inds <- c(1,11,21,31,41,51,61,71,81,91)
select_files <- wav_files[inds]
select_genres <- genres[inds]

for (i in 1:length(select_files)) {
  spect <- vis_mel_spect(select_files[i])+ggtitle(paste0('Mel Spectrogram (',select_genres[i],')'))+theme_classic(base_size = 18)
  ggsave(
    filename = paste0("spects/spect_",select_genres[i],'.png'),  # File name
    plot = spect,                   # The plot object to save
    width = 16,                             # Width of the plot in inches
    height = 10,                            # Height of the plot in inches
    dpi = 300                               # Resolution (dots per inch)
  )
}
