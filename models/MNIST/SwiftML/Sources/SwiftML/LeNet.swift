// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Datasets
import TensorFlow
import TrainingLoop
import CoreFoundation

func LeNetTrainMNIST(_ epochCount: Int = 5, _ batchSize: Int = 128) {

    // Until https://github.com/tensorflow/swift-apis/issues/993 is fixed, default to the eager-mode
    // device on macOS instead of X10.
#if os(macOS)
      let device = Device.defaultTFEager
#else
      let device = Device.defaultXLA
#endif

    let dataset = MNIST(batchSize: batchSize, on: device)

    // The   model, equivalent to `LeNet` in `ImageClassificationModels`.
    var classifier = Sequential {
        Conv2D<Float>(filterShape: (5, 5, 1, 6), padding: .same, activation: relu)
        AvgPool2D<Float>(poolSize: (2, 2), strides: (2, 2))
        Conv2D<Float>(filterShape: (5, 5, 6, 16), activation: relu)
        AvgPool2D<Float>(poolSize: (2, 2), strides: (2, 2))
        Flatten<Float>()
        Dense<Float>(inputSize: 400, outputSize: 40, activation: relu)
        Dense<Float>(inputSize: 40, outputSize: 20, activation: relu)
        Dense<Float>(inputSize: 20, outputSize: 10)
    }

    let optimizer = SGD(for: classifier, learningRate: 0.1)

    let trainingProgress = TrainingProgress()
    var trainingLoop = TrainingLoop(
      training: dataset.training,
      validation: dataset.validation,
      optimizer: optimizer,
      lossFunction: softmaxCrossEntropy,
      callbacks: [trainingProgress.update])
    
    let startTime = CFAbsoluteTimeGetCurrent()
    try! trainingLoop.fit(&classifier, epochs: epochCount, on: device)
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed: \(Double(timeElapsed)) s.")
    
    // plot our accuracies and losses
    let acc = trainingProgress.accuracies
    let loss = trainingProgress.losses
    plot(acc: acc, loss: loss, fname: "mnist.pdf")
}

