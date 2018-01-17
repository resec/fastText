/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#include "args.h"

#include <stdlib.h>

#include <iostream>
#include <stdexcept>

namespace fasttext {

Args::Args() {
  lr = 0.05;
  dim = 100;
  ws = 5;
  epoch = 5;
  minCount = 5;
  minCountLabel = 0;
  neg = 5;
  wordNgrams = 1;
  loss = loss_name::ns;
  model = model_name::sg;
  bucket = 2000000;
  minn = 3;
  maxn = 6;
  thread = 12;
  lrUpdateRate = 100;
  t = 1e-4;
  label = "__label__";
  verbose = 2;
  pretrainedVectors = "";
  saveOutput = false;

  qout = false;
  retrain = false;
  qnorm = false;
  cutoff = 0;
  dsub = 2;
}

std::string Args::lossToString(loss_name ln) const {
  switch (ln) {
    case loss_name::hs:
      return "hs";
    case loss_name::ns:
      return "ns";
    case loss_name::softmax:
      return "softmax";
  }
  return "Unknown loss!"; // should never happen
}

std::string Args::boolToString(bool b) const {
  if (b) {
    return "true";
  } else {
    return "false";
  }
}

std::string Args::modelToString(model_name mn) const {
  switch (mn) {
    case model_name::cbow:
      return "cbow";
    case model_name::sg:
      return "sg";
    case model_name::sup:
      return "sup";
  }
  return "Unknown model name!"; // should never happen
}

void Args::printHelp() {
  printBasicHelp();
  printDictionaryHelp();
  printTrainingHelp();
  printQuantizationHelp();
}


void Args::printBasicHelp() {
  std::cerr
    << "\nThe following arguments are mandatory:\n"
    << "  -input              training file path\n"
    << "  -output             output file path\n"
    << "\nThe following arguments are optional:\n"
    << "  -verbose            verbosity level [" << verbose << "]\n";
}

void Args::printDictionaryHelp() {
  std::cerr
    << "\nThe following arguments for the dictionary are optional:\n"
    << "  -minCount           minimal number of word occurences [" << minCount << "]\n"
    << "  -minCountLabel      minimal number of label occurences [" << minCountLabel << "]\n"
    << "  -wordNgrams         max length of word ngram [" << wordNgrams << "]\n"
    << "  -bucket             number of buckets [" << bucket << "]\n"
    << "  -minn               min length of char ngram [" << minn << "]\n"
    << "  -maxn               max length of char ngram [" << maxn << "]\n"
    << "  -t                  sampling threshold [" << t << "]\n"
    << "  -label              labels prefix [" << label << "]\n";
}

void Args::printTrainingHelp() {
  std::cerr
    << "\nThe following arguments for training are optional:\n"
    << "  -lr                 learning rate [" << lr << "]\n"
    << "  -lrUpdateRate       change the rate of updates for the learning rate [" << lrUpdateRate << "]\n"
    << "  -dim                size of word vectors [" << dim << "]\n"
    << "  -ws                 size of the context window [" << ws << "]\n"
    << "  -epoch              number of epochs [" << epoch << "]\n"
    << "  -neg                number of negatives sampled [" << neg << "]\n"
    << "  -loss               loss function {ns, hs, softmax} [" << lossToString(loss) << "]\n"
    << "  -thread             number of threads [" << thread << "]\n"
    << "  -pretrainedVectors  pretrained word vectors for supervised learning ["<< pretrainedVectors <<"]\n"
    << "  -saveOutput         whether output params should be saved [" << boolToString(saveOutput) << "]\n";
}

void Args::printQuantizationHelp() {
  std::cerr
    << "\nThe following arguments for quantization are optional:\n"
    << "  -cutoff             number of words and ngrams to retain [" << cutoff << "]\n"
    << "  -retrain            whether embeddings are finetuned if a cutoff is applied [" << boolToString(retrain) << "]\n"
    << "  -qnorm              whether the norm is quantized separately [" << boolToString(qnorm) << "]\n"
    << "  -qout               whether the classifier is quantized [" << boolToString(qout) << "]\n"
    << "  -dsub               size of each sub-vector [" << dsub << "]\n";
}

void Args::save(std::ostream& out) {
  out.write((char*) &(dim), sizeof(int));
  out.write((char*) &(ws), sizeof(int));
  out.write((char*) &(epoch), sizeof(int));
  out.write((char*) &(minCount), sizeof(int));
  out.write((char*) &(neg), sizeof(int));
  out.write((char*) &(wordNgrams), sizeof(int));
  out.write((char*) &(loss), sizeof(loss_name));
  out.write((char*) &(model), sizeof(model_name));
  out.write((char*) &(bucket), sizeof(int));
  out.write((char*) &(minn), sizeof(int));
  out.write((char*) &(maxn), sizeof(int));
  out.write((char*) &(lrUpdateRate), sizeof(int));
  out.write((char*) &(t), sizeof(double));
}

void Args::load(std::istream& in) {
  in.read((char*) &(dim), sizeof(int));
  in.read((char*) &(ws), sizeof(int));
  in.read((char*) &(epoch), sizeof(int));
  in.read((char*) &(minCount), sizeof(int));
  in.read((char*) &(neg), sizeof(int));
  in.read((char*) &(wordNgrams), sizeof(int));
  in.read((char*) &(loss), sizeof(loss_name));
  in.read((char*) &(model), sizeof(model_name));
  in.read((char*) &(bucket), sizeof(int));
  in.read((char*) &(minn), sizeof(int));
  in.read((char*) &(maxn), sizeof(int));
  in.read((char*) &(lrUpdateRate), sizeof(int));
  in.read((char*) &(t), sizeof(double));
}

void Args::dump(std::ostream& out) const {
  out << "dim" << " " << dim << std::endl;
  out << "ws" << " " << ws << std::endl;
  out << "epoch" << " " << epoch << std::endl;
  out << "minCount" << " " << minCount << std::endl;
  out << "neg" << " " << neg << std::endl;
  out << "wordNgrams" << " " << wordNgrams << std::endl;
  out << "loss" << " " << lossToString(loss) << std::endl;
  out << "model" << " " << modelToString(model) << std::endl;
  out << "bucket" << " " << bucket << std::endl;
  out << "minn" << " " << minn << std::endl;
  out << "maxn" << " " << maxn << std::endl;
  out << "lrUpdateRate" << " " << lrUpdateRate << std::endl;
  out << "t" << " " << t << std::endl;
}

}
