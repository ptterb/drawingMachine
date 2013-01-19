float[] spectrum(AudioBuffer buffer) {

  // FFT on the given mix
  fft.forward(buffer);

  // Array to hold amplitude for all freq bands
  float[] bands = new float[fft.specSize()];

  // loop over the bands and draw to make an equalizer
  for (int i = 0; i < fft.specSize(); i++) {
    fill(255);
    rect(i*10, height - fft.getBand(i)*10, 10, fft.getBand(i)*10 ); 

    // Put the amplitudes of all the bands into an array
    bands[i] = fft.getBand(i);
  }
  // return the array of band values to be analyzed
  return bands; 
}


// analyze band values and check against the current max values
void analyze(float[] bands) {
  // Grab the amplitude of the loudest band - (Volume)
  float currMax = max(bands);       // Current loudest band this time around

  // If the current max is larger than the running max, 
  // set the new max, also note which freq band is loudest (index)
  if (currMax > maxAmp) {
    maxAmp = currMax;
    // Grab the position in the array of the max amplitude - this is the freq band that is the loudest (Pitch)
    for (int i = 0; i < bands.length; i++) {
      if (bands[i] == currMax) {
        maxPitch = i;
      }
    }
  }
}

