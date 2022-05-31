---
title: "Run Machine Learning Experiments with Docker Containers"
subtitle: "Quick reproducibility and mobility - how to run your experiments"
layout: post
date: 2020-04-18 00:00
tag:
  - Machine Learning
  - Docker
  - Experiments
image: noimage
headerImage: false
projects: false
description: ""
category: blog
author: gaborvecsei
externalLink: false
---

Docker images and containers. You heard about it, or even someone uses it for model deployment. But it's not so common to run experiments with. Most of the researchers, data scientists and machine learning engineers find it cumbersome to set it up and pay attention to an extra tool in the workflow. You can easily feel this, because most of the tutorials and blog posts about docker containers with machine learning targets only the deployment phase. But containerization is just as important in the experimentation period as at the end in production. For the following simple reason: **Quick Reproducibility** and **Mobility**. Nowadays you can hear these term more often than ever (reproducibility crisis in the field *[1]*), but still, people don't really care about the fact that they will forget the little tricks which makes their code work and produce the same results as before. And that they are working in a team, so anyone should easily have the same setups with the same runs as any member of the team.

I am not saying that only with containers you can solve this problem, but with a combination of docker and an experiment tracking system you are performing better than 70% *[2]* of companies where ML is used. In this post I would like to show you the benefits of Docker and the workflow/setup which I found the most useful.

# Why would you care?

I met with multiple projects where there was a "golden" model which was trained by 1 guy/girl over and over again without recording any history on loaded weights or modifications, requirements. Then as always, the time has come and someone wanted to run the experiments again, and it took days before the training/evaluation started. Why? Because none of the dependencies were recorded. Not a single `requirements.txt` file. Not even a napkin with some hand notes and ketchup. As I said it was trained over and over again so if you'd like to follow that chain you need multiple trainings and of course the requirements changed so you had to spend another 2-3 days on the setup and the perfect combination of package versions. Finally you managed to run the training but it's nowhere near the recorded KPIs. After a week of debugging you realize that `python 3.7` was used but with `python 3.5` and another package version combination you can get the desired results...hopefully.

Unfortunately this is not (always) the case. In the real world, **even the author of the model can not reproduce the recorded numbers**.

# Experiments inside containers

In the above mentioned scenario with a proper image the process would have been a few minutes/hours. This is just one positive fact about this method but there are others. You can limit the HW access *[3]* of the containers. This comes handy when multiple researchers use the same HW so a single experiment won't eat all the CPUs because of a misconfiguration. Also you won't need to look through processes and manage tmux/screen sessions. All your running trainings will be accessible with a simple `docker ps` command. Even, after power outage (on the weekend) you can configure the container to restart itself when the power comes back.

Let's see how can we use containers for the experiments.

First of all it's good to know what are the main components we have:
- Scripts - training, evaluation, visualization, etc.
- Configuration
- Data data data
- Runtime environment

With the scripts we can run the experiments, and often with a configuration file or simple command line arguments we can set it's parameters. Data is often huge, stored on a disk and without it you won't run the experiment 😉. The runtime environment enables us to run these scripts.

## Workflows

We have multiple choices on setting up the workflow. We can be sure in one thing: we will mount the data to the container as it is too big to include in the image itself.

One of the best solution from the reproducibility perspective is when we **build a new image before every run and our code and configuration is copied to the image itself**. After this you could sleep well, as the current state of the code and setup is preserved within the image. Unfortunately this way we need to store all of our built images in a container registry which would take up a lot of space, so we can try to get rid of the experiment images which did not bring any value. Just pay attention that in machine learning experiments low KPIs can be valuable, as it shows direction. Still, with this reduction we can end up with many images, and a single image can take up to 5-10 GB.

Instead, **we can wrap the runtime only** to an image and rebuild and store it only when the environment changes. *But then how to run the code if we can not access it?* Just create a bash script which is the entrypoint of the container and it does the following: clones a specific commit hash, then executes the main file which starts the experiment (The well known `train.py` file 😏). The config file should be mounted as it could contain secrets (e.g. database access) and we do not want to trash our repo with unnecessary config files for every experiment. *Why not mount the code also?* That would result in confusion as if you run multiple experiments and you just change the branch the code will be changed in every of your containers (as it is just mounted).

This workflow helps with dirty commits as you need to push your changes on a branch before starting anything. Rebuilding is only needed when the dependencies change which results in much fewer images which can be easily used and it's easily manageable.

There are also things to pay attention to. When you start a run, make notes on the docker image name and tag, the git commit hash which you are using and the configuration file along with your results. In a setup like this, these ensure reproducibility. Basically next time you'd like to run it again, just `docker run -d -v config.yaml:/config.yaml -v data:/data start.sh GIT_COMMIT_HASH`. Or if your coworker would like to test your code you only need to point to your docker image in the container registry and a 3 liner experiment note (which contains the commit hash, etc.).

# Conclusion

In this post we saw how we can put just a bit of extra work into our projects which pays off in the near future. This is not a "toy model", the workflow is actually is in use in my teams. Based on my experience within 1-2 weeks everyone gets used to the new tool and way of working. Of course with different teams and different workloads, projects this might be different, so take my words with a pinch of salt. You should experiment with different workflows which fits for your load and infrastructure.


[1] [Pete Warden - The Machine Learning Reproducibility Crisis](https://petewarden.com/2018/03/19/the-machine-learning-reproducibility-crisis/)

[2] This is just a personal feeling about the situation, based on my experience at multiple companies (startups and multinational) and based on discussions with other ML practitioners (scientists and engineers) (in Central Europe)

[3] [Runtime options with Memory, CPUs, and GPUs](https://docs.docker.com/config/containers/resource_constraints/)
