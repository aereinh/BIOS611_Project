Hi, this is my 611 Data Science Project, where I explore the GTZAN Dataset for music genre classication available here on Kaggle: https://www.kaggle.com/datasets/andradaolteanu/gtzan-dataset-music-genre-classification.

To generate my report, run

docker build -t bios611 .

docker run -it -v $(pwd):/project bios611

make clean

make all



Notes:

- make clean does not delete the report.pdf automatically. You can try removing it if you want to verify the above procedure works.

-If all else fails, the necessary R packages are located in requirements.R

-The models are saved in a directory, since otherwise the make all would take nearly an hour. You should be able to still run the training from the container. The call would be (after running docker run ...):

Rscript scripts/Feat_Classifiers_Training.R

-For the spectrogram figures (as with below), I couldn't successfully load in torchaudio to my container. I had to save the results from a the script: scripts/visualize_spectrogram.R, which is included in the repo.

-I do also have an interactive visualization app, but unfortunately could not successfully integrate this into my container since I had a hard time integrating the necessary Python package torchaudio. If you are interested in using it, the script is called visualize_spectrograms.R. After you clone the Git repository, you would need to install the following packages in R to use the app:

shiny, shinyjs, ggplot2, reshape2, torchaudio, base64enc (commented out in requirements.R)

The app automatically visualizes the Mel spectrogram for an inputted .wav file, allowing you to change Mel spectrogram parameters to see how this affects the temporal and frequency resolutions (while also listening to the song).
