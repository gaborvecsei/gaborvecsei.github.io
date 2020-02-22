---
title: "Playing with Monte-Carlo dropout for uncertainty estimation"
subtitle: ""
layout: post
date: 2020-02-16 00:00
tag:
  - Deep Learning
  - Machine Learning
  - Variational inference
image: ../assets/posts/nonexistent.png
headerImage: false
projects: true
hidden: true
description: "Playing with Monte-Carlo dropout for uncertainty estimation"
category: project
author: gaborvecsei
externalLink: false
---

## Introduction

Imagine you created a deep learning model which can classify cats and dogs. You collected various cat images but you could only find sausage dogs for the other class. Your NN is trained and evaluated (reaching pretty nice management compatible KPIs), **production ready** we could say. But after the deployment the NN meets with the first non-sausage dog image, a labrador. What should the model do, what is the proper output? Just think about this for a few seconds.

When you train a classifier the prediction produced by the model is just a label and most probably a softmax score. Some of the people use this softmax score as the "confidence/certainty" of the result (- "if it is 0.8 then my model is 80% certain about it's prediction"). This is problematic as NNs tend to be too confident and it can output high softmax values while it is uncertain *[3]*.

In a scenario when our model meets with a new kind of dog, I would expect my NN to tell me - "looks like a dog but I am not sure" or just "I am not sure, please check". This is called *epistemic* uncertainty, which comes from the lack of knowledge *[1]*. This can be improved by collecting more relevant data *[2]*. (In our example the researcher should collect different kind of breeds of dogs.) At the same time we can have a prediction like "I don't know" and this can be reached by [variational inference](https://en.wikipedia.org/wiki/Variational_Bayesian_methods). I won't write about the theoretical part of *VI*, as you can find a lot of materials, but trust me, Bayesian approaches compared to frequntist deep learning are (computationally) expensive. This is why I really liked the *Monte Carlo Dropout* concept which says that a NN which conatins dropout layers can be interpreted as an approximation to the probabilistic deep Gaussian process *[3]*. This means that you won't need new architectures or training methods, it works almost out of the box (take this with a pinch of salt). With that being said, let's get to the experimental part where I tried it out to see how it works.

## Uncertainty estimation

The question comes. What should I do to receive an "uncertainty score" for a prediction?

Take a model with dropout layers and then activate those at inference time also, forcing the network to mask certain connections. Now you just need to perform inference on a single image multiple times and record it's outputs. From the gathered data you can calculate the mean and variance (or entropy for classification tasks) of the predictions, which gives you the uncertainty. I can hear your thoughs - "but what is uncertainty? standard deviation 0.5?, entropy 0.1?". This is something which you need to define, and create a metric and the logic in your application.

## Experiments

I trained a model which contains dropout after every convolutional and fully connected layer but the last one which provides the outputs.

<img src="https://raw.githubusercontent.com/gaborvecsei/CDCGAN-Keras/master/art/cdcgan_abstract_model.png" width="640" alt="Model">

For the data I choose the [MNIST](http://yann.lecun.com/exdb/mnist/) dataset without any augmentation and trained my network.

You can make the dropout layers active during inference time:

```
tf.keras.layers.Dropout(0.5)(x, training=True)
``` 

I choose a random image and then transformed it throuh multiple iterations to see how the prediction and uncertainty varies. Every image is fed to the network $1000$ times, then I calculate the softmax score mean, variance and entropy.

### Rotation

In the following experiment a random image with the label $1$ was selected and then rotated with $10$ degrees at each step.

<img src="https://raw.githubusercontent.com/gaborvecsei/CDCGAN-Keras/master/art/cdcgan_abstract_model.png" width="640" alt="Model">

The same experiment with a "MC Dropout free" model, would produce only the top softmax value plot. This is problematic as with a carelessly selected softmax threshold (let's say with $0.5$) we can introduce false detections when it would be much better to say "I don't know". (The plot above illustrates this at steps 10, 11, 12, 13, 28, 29, 30).

With the knowledge of the other metrics we can see our model is uncertain because it has high variance at those regions.


### Blending

2 random images are selected and we start to blend them. I would expect that as more and more becomes visible from the second image the more uncertain my model will be. Fortunately this is exactly what happened.

<img src="https://raw.githubusercontent.com/gaborvecsei/CDCGAN-Keras/master/art/cdcgan_abstract_model.png" width="640" alt="Model">

Our model always predicted the correct label for the image, but the entropy and variance increased over the steps. Around step 15 as a human I would not be confident what is the correct label and this is exactly what we achieved with the MC Dropout.

## Conclusion

The drawback is that you need to make multiple inference steps with the NN to calculate meaningful variance. We also should not forget that our model is still dependent on the dropout and activation hyperparameters which can modify the received variance.
Overall this is an interesting and lightweight approach to model prediction uncertainty, which I will use in future projects for better filtering options.

## References

*[1]* - [Aleatory or epistemic? does it matter?, *2009*](https://www.researchgate.net/publication/222422822_Aleatory_or_Epistemic_Does_It_Matter)

*[2]* - [Single-Model Uncertainties for Deep Learning, *2018*](https://arxiv.org/abs/1811.00908)

*[3]* - [Dropout as a Bayesian Approximation: Representing Model Uncertainty in Deep Learning, *2015*](https://arxiv.org/abs/1506.02142)