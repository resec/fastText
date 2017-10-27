#include "fasttext.h"

#include <iostream>
#include <sstream>
#include <string>
#include <vector>


namespace fasttext {

FastText::FastText() : quant_(false) {}

bool FastText::checkModel(std::istream& in) {
  int32_t magic;
  in.read((char*)&(magic), sizeof(int32_t));
  if (magic != FASTTEXT_FILEFORMAT_MAGIC_INT32) {
    return false;
  }
  in.read((char*)&(version), sizeof(int32_t));
  if (version > FASTTEXT_VERSION) {
    return false;
  }
  return true;
}

bool FastText::loadModel(const std::string& filename) {
  std::ifstream ifs(filename, std::ifstream::binary);
  if (!ifs.is_open()) {
    std::cerr << "Model file cannot be opened for loading!" << std::endl;
    return false;
  }
  if (!checkModel(ifs)) {
    std::cerr << "Model file has wrong file format!" << std::endl;
    return false;
  }
  const bool load = loadModel(ifs);
  ifs.close();
  return load;
}

bool FastText::loadModel(std::istream& in) {
  args_ = std::make_shared<Args>();
  dict_ = std::make_shared<Dictionary>(args_);
  input_ = std::make_shared<Matrix>();
  output_ = std::make_shared<Matrix>();
  qinput_ = std::make_shared<QMatrix>();
  qoutput_ = std::make_shared<QMatrix>();
  args_->load(in);
  if (version == 11 && args_->model == model_name::sup) {
    // backward compatibility: old supervised models do not use char ngrams.
    args_->maxn = 0;
  }
  dict_->load(in);

  bool quant_input;
  in.read((char*) &quant_input, sizeof(bool));
  if (quant_input) {
    quant_ = true;
    qinput_->load(in);
  } else {
    input_->load(in);
  }

  in.read((char*) &args_->qout, sizeof(bool));
  if (quant_ && args_->qout) {
    qoutput_->load(in);
  } else {
    output_->load(in);
  }

  model_ = std::make_shared<Model>(input_, output_, args_, 0);
  model_->quant_ = quant_;
  model_->setQuantizePointer(qinput_, qoutput_, args_->qout);

  if (args_->model == model_name::sup) {
    model_->setTargetCounts(dict_->getCounts(entry_type::label));
  } else {
    model_->setTargetCounts(dict_->getCounts(entry_type::word));
  }
  return true;
}

std::string FastText::detect(const std::string& text) const {
  std::vector<int32_t> words, labels;
  std::istringstream in(text);
  dict_->getLine(in, words, labels, model_->rng);
  if (words.empty()) return "";
  std::vector<std::pair<real,int32_t>> modelPredictions;
  model_->predict(words, 1, modelPredictions);
  return dict_->getLabel(modelPredictions.cbegin()->second);
}

}
