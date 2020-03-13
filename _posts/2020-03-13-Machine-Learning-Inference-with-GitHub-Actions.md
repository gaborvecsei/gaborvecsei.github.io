---
title: "Machine Learning Inference with GitHub Actions"
subtitle: ""
layout: post
date: 2020-03-13 00:00
tag:
  - Machine Learning
  - Deployment
  - GitHub
  - CI/CD
image: https://gaborvecsei.github.io/assets/images/blog/ml_github_actions/issue_comment_prediction.png
headerImage: false
projects: false
description: "This post demonstrated how you can use GitHub Actions to perform inference with your ML models inside GitHub"
category: blog
author: gaborvecsei
externalLink: false
---

I just looked up the new [GitHub Actions](https://github.com/features/actions) and my first thought was to create an example project where we "deploy" an ML model with actions. Of course this is not a real deployment, but it could be great to test your model quickly without any coding. It could be even done from your phone... Wow, so 2020.
Or you can look super cool when you say to your boss, - "just leave an issue comment at the github repo I've created". Moments later a new notification will appear for him/her that the model has the prediction.

[You can find the **complete GitHub repo** here](https://github.com/gaborvecsei/Machine-Learning-Inference-With-GitHub-Actions)

GitHub Actions is an automation tool for building, testing, deployment. Quick example: every time you create a Pull Request (with a certain tag), a new build will be triggered for your application and then it can send a message to a senior developer to have a quick look on your code.

# What will we create?

A new GitHub repo will be created where we store the code which trains and performs inference for a machine learning model. I wanted to be super hardcore, so I chose the [Iris dataset](https://en.wikipedia.org/wiki/Iris_flower_data_set) and a [Random Forest Classifier](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html). This classifier is trained so it can identify flowers based on the sepal and petal lengths and widths. The model training can be found [here](https://github.com/gaborvecsei/Machine-Learning-Inference-With-GitHub-Actions/blob/master/train_model.ipynb) (I'll leave this explanation out as there is nothing interesting about it). The notebook produces a model file which will be used for the predictions. The GitHub Actions workflow is triggered when an issue receives a comment. If the comment contains the `/predict` prefix, then we start to parse the comment, then we make a prediction and construct a reply. As the final step this message is sent back to the user by a bot. To make it better, this whole thing runs inside a Docker container.

<img src="https://gaborvecsei.github.io/assets/images/blog/ml_github_actions/issue_comment_prediction.png" alt="sample comment prediction">

In a **workflow** we will find **steps** and for certain steps **we can create individual actions**. One workflow can contain multiple actions, but in this project we will use only 1.

# Create an Action

As a first step we should create our action in the root folder named `action.yaml`. In this we can describe the *inputs*, *outputs* and the environment.

{% gist gaborvecsei/45a7a0a1c681d23370d233fb26ebeaf2 %}

You can see the 3 inputs and a single output. Also the `runs` key describes the environment where our code will run. This is a Docker container for which the inputs will be passed as arguments. Therefore the entry point of the container should accept these 3 arguments in the defined order. This Docker image is described here: [Dockerfile](https://github.com/gaborvecsei/Machine-Learning-Inference-With-GitHub-Actions/blob/master/Dockerfile). When we run the container it launches the `entrypoint.sh` script.

## The container

When we take a closer look on the *Dockerfile* we can see what is really happening. First we install all the listed python requirements. Then the `entrypoint.sh` is initialized, so it can be run inside the container. Lastly the produced random forest sklearn model file is copied to the container, so we can use it for the prediction (in a real life scenario, you should not store model files in a repo. This is just for the sake of quick demonstration and laziness).

```python
FROM python:3.6

# Install python requirements
COPY requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

# Setup Docker entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy the trained model
COPY random_forest_model.pkl /random_forest_model.pkl

ENTRYPOINT ["/entrypoint.sh"]
```

# Define the Workflow

<img src="https://gaborvecsei.github.io/assets/images/blog/ml_github_actions/job_steps.png" alt="job steps">

An action can not be used without a workflow. That defines the different steps you would like to take in your pipeline. You can find it at [`.github/workflows/main.yaml`](https://github.com/gaborvecsei/Machine-Learning-Inference-With-GitHub-Actions/blob/master/.github/workflows/main.yaml).

{% gist gaborvecsei/c57a7fe8e16cdc645d01d96366d743dc %}

First of all `on: [issue_comment]` defines that I would like to trigger this flow when an issue receives a comment (from anyone). Then in my job I define the VM type with `runs-on: ubuntu-latest`. Now comes the interesting part, the steps which I mentioned before.

- *Checkout step*: with this step we move to the desired branch in out repository (this is a github action also).
- *See the payload*: I left it for debugging. It shows the whole payload after receiving a comment under an issue. This container the comment, the issue number, the user who left the comment, etc.
- *Make the prediction*: This is the step for our custom action. The `if: startsWith(github.event.comment.body, '/predict')` line makes sure this step runs only if a valid "prediction request" came in (so it contain the `/predict` prefix). You can see the inputs are defined with the `with` keyword and the values are added from the payload through different keys (like `github.event.comment.body`).
- *Print the reply*: The constructed reply is echoed to the log. It uses the defined output of out previous step: `steps.make_prediction.outputs.issue_comment_reply`.
- *Send reply*: The created reply which contains the prediction is sent as a reply with the script `issue_comment.sh`.

# Making the prediction

There is one thing I've not talked about: how the prediction is made? You can easily figure this out by looking at the [`main.py`](https://github.com/gaborvecsei/Machine-Learning-Inference-With-GitHub-Actions/blob/master/main.py) script.

```python
model = load_model("/random_forest_model.pkl")

try:
    sepal_length, sepal_width, petal_length, petal_width = parse_comment_input(args.issue_comment_body)
    predicted_class_id = make_prediction(model, sepal_length, sepal_width, petal_length, petal_width)
    predicted_class_name = map_class_id_to_name(predicted_class_id)
    reply_message = f"Hey @{args.issue_user}!<br>This was your input: {args.issue_comment_body}.<br>The prediction: **{predicted_class_name}**"
except Exception as e:
    reply_message = f"Hey @{args.issue_user}! There was a problem with your input. The error: {e}"

print(f"::set-output name=issue_comment_reply::{reply_message}")
```

First of all the serialized sklearn model is loaded. Then the comment is parsed and we receive the 4 feature which can be used to identify the flower. With these features we can immediately use the model for prediction. The last step is to construct the reply message and then set it as an output (which is done with the `print(f"::set-output name=issue_comment_reply::{reply_message}")` line).

That's it! Okay... I know what you are thinking. This is too easy: The input, the dataset, the model, the storage of the mode, how the request is handled, etc. But I am suer you can figure out how to develop from here. E.g. for image inputs you could decode from a base64 string and then run it through your Deep Learning model which is stored in GitLFS.