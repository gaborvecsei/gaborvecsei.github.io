---
title: "Conditional Deep Convolutional GAN Keras Implementation"
subtitle: "Conditional Deep Convolutional GAN Keras Implementation"
layout: post
date: 2019-01-08 00:00
tag:
  - Python
  - Keras
  - Deep Learning
  - Machine Learning
  - GAN
image: ../assets/posts/nonexistent.png
headerImage: false
projects: true
hidden: true # don't count this post in blog pagination
description: "Conditional Deep Convolutional GAN Keras Implementation"
category: project
author: gaborvecsei
externalLink: false
---

In this really short post I will show the overall architecture and the results of a **Conditional DCGAN**.
There are several tutorials and explanations for *GAN*s, so the intention with post is just to showcase the results and share the code. 

Implementation can be found [**here**](https://github.com/gaborvecsei/CDCGAN-Keras) 

> Why is it *conditional*?

Because we are using an extra piece of class information besides the random noise input.
That means we can control the class of the generated image based on a input label.

## Architecture

<img src="https://github.com/gaborvecsei/CDCGAN-Keras/blob/master/art/cdcgan_abstract_model.png" width="640" alt="Model">

### Generator $G(z, c)$

The input for the generator is a noise vector $z \in N(0, 1)$ and a condition vector $c$ which describes the label which we want to generate.
With $c$ the $G(z, c)$ model will learn the conditional distribution of the data.

### Discriminator $D(X, c)$

The goal of the discriminator is to decide if the input image with the condition vector $c$ came from the original dataset or from $G$.

## Results

Generated digits at every epoch:

<img src="https://github.com/gaborvecsei/CDCGAN-Keras/blob/master/art/mnist_generated_per_epoch.gif" width="640" alt="Generated MNIST Characters">

Linear interpolation results:

<img src="https://github.com/gaborvecsei/CDCGAN-Keras/blob/master/art/interpolation_2_to_4.gif" width="250" alt="Interpolation animation"><img src="https://github.com/gaborvecsei/CDCGAN-Keras/blob/master/art/interpolation_8_to_5.gif" width="250" alt="Interpolation animation"><img src="https://github.com/gaborvecsei/CDCGAN-Keras/blob/master/art/interpolation_9_to_6.gif" width="250" alt="Interpolation animation">