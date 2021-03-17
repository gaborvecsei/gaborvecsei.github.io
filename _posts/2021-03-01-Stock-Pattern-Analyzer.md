---
title: "Finding patterns in stock data with similarity matching - Stock Pattern Analyzer"
subtitle: "Find similar patterns in historical stock data"
layout: post
date: 2021-03-01 00:00
tag:
  - Stocks
  - Optimization
  - Python
image: ../assets/images/stock_analyzer/stock_analyzer_image.png
headerImage: false
description: ""
category: blog
author: gaborvecsei
externalLink: false
---

<img src="https://github.com/gaborvecsei/Stocks-Pattern-Analyzer/raw/master/art/homepage.png" alt="stock patterns tool" width=1 height=1>

In financial (or almost any type of) forecasting we build models which learn the patterns of the given series.
Partially this can be done because the investors and traders tend to make the same choices they did in the past, 
as they follow the same analysis techniques and their objective rules (e.g.: if a given stock drop below $x$,
then I'll sell).
Just look at the textbook examples below *[1]*.

Algorithmic trading, which covers ~80% *[8] [9]* of the trading activity introduces similar patterns
as they often based on the same techniques and fundamentals.
These can be observed at different scales (e.g. high-frequency trading) 

In this pet-project I wanted to create a tool with which we can directly explore the most similar patterns
in $N$ series given a $q$ query. The idea was that, if I look at the last $M$ trading days for a selected stock, and
I find the most similar matches from the other $N$ stocks where I also know the "future" values (which comes after the
$M$ days), then it can give me a hint on how the selected stock will move in the future.
For example, I can observe the top $k$ matches, and then a majority vote could decide,
if a bullish or bearish period will come. 

<img src="https://www.newtraderu.com/wp-content/uploads/2020/06/Trading-Patterns-Cheat-Sheet.jpg" alt="stock patterns" width=300>

*(Source: [1])* 

# Search Engine

The approach would be quite simple if we would't care about runtime.
Just imagine a sliding window over all stocks which you select, then a calculation of some distance metric and bummm 💥,
you have the closest matches.
**But we want better than that**, as even a 1 second response time can be depressing for an end user.
Let's get to how it can be "optimized".

Instead of the naive sliding window approach which has the biggest runtime complexity,
we can use more advanced similarity search methods *[2]*.
In the project I used 2 different solutions:
- KDTree *[7]* *[3]*
- Faiss Quantized Index *[4]*

Both are blazing ⚡ fast compared to the basic approach.
The only drawback is that you need to build a data model to enable this speed and keep it in the memory.
As long as you don't care how much memory is allocated, you can choose which ever you want.
But when you do, I'd recommend the quantized approximate similarity search from Faiss.
You can quantize your data and by that you can reduce the memory footprint of the objects with more than a magnitude.
Of course the price is that this is an approximate solution *[2]*, but still, you will get satisfying results.
At least this was the case in this stock similarity search project.

You can see the comparison of the different solutions at the measurements section.

## Window extraction

To build a search model for a given length (measured in days) which we call dimensions, you'll need to prepare
the data in which you would like to search in later on.
In our case this means a sliding window *[6]* across the data with a single step.
To speed it up we can vectorize this step with `numpy`:

```python
window_indices = np.arange(values.shape[0] - window_size + 1)[:, None] + np.arange(window_size)
extracted_windows = values[window_indices]
```

Now that we have the extracted windows we can build the search model.
But wait... It's sounds great that we have the windows, but we actually don't care about the "real 💲💲💲 values" for a
given window. We are interested in the patterns, the ups 📈🦧 and downs 📉.
We can solve this by min-max scaling the values for each window (this is also vectorized).
This way we can directly compare the patterns in them.

Building the search tree/index is different for each library, with `scipy`'s `cKDTree` it looks like this:

```python
X = min_max_scale(extracted_windows)
# At this point the shape of X is: (n_windows, dimensions)
model = cKDTree(X)
``` 

(To build a Faiss index, you can check the code [at my repo](https://github.com/gaborvecsei/Stocks-Pattern-Analyzer/blob/master/stock_pattern_analyzer/search_index.py#L50))

The RAM allocations and build times are compared below in the measurements section.

## Query

We have a search model, now we can start to use it to find the most similar patterns in our dataset.
We only need to define a constant $k$ which defines how many (approximate) top-results we would like to receive and a 
min-max scaled query which has the same dimensions as the data we used to build the model.

```python
top_k_distances, top_k_indices = model.query(x=query_values, k=5)
```

The query speed of the models can be found in the measurement table below.

# Measurement results

<div style="overflow-x: auto;">
<table border="1" class="dataframe">
  <thead>
    <tr>
      <th></th>
      <th colspan="5" halign="left">Build Time (ms)</th>
      <th colspan="5" halign="left">Memory Footprint (Mb)</th>
      <th colspan="5" halign="left">Query Speed (ms)</th>
    </tr>
    <tr>
      <th>window sizes</th>
      <th>5</th>
      <th>10</th>
      <th>20</th>
      <th>50</th>
      <th>100</th>
      <th>5</th>
      <th>10</th>
      <th>20</th>
      <th>50</th>
      <th>100</th>
      <th>5</th>
      <th>10</th>
      <th>20</th>
      <th>50</th>
      <th>100</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>FastIndex</th>
      <td>0.80</td>
      <td>1.30</td>
      <td>1.81</td>
      <td>13.57</td>
      <td>26.98</td>
      <td>3.48</td>
      <td>6.96</td>
      <td>13.92</td>
      <td>34.80</td>
      <td>69.58</td>
      <td>1.03</td>
      <td>1.27</td>
      <td>2.47</td>
      <td>7.79</td>
      <td>15.56</td>
    </tr>
    <tr>
      <th>MemoryEfficientIndex</th>
      <td>6967.66</td>
      <td>7058.32</td>
      <td>5959.26</td>
      <td>8216.05</td>
      <td>7485.01</td>
      <td>2.27</td>
      <td>2.28</td>
      <td>2.12</td>
      <td>2.33</td>
      <td>2.22</td>
      <td>0.23</td>
      <td>0.35</td>
      <td>0.25</td>
      <td>0.23</td>
      <td>0.42</td>
    </tr>
    <tr>
      <th>cKDTreeIndex</th>
      <td>110.23</td>
      <td>135.16</td>
      <td>206.76</td>
      <td>319.94</td>
      <td>484.34</td>
      <td>10.60</td>
      <td>17.57</td>
      <td>31.49</td>
      <td>73.24</td>
      <td>142.80</td>
      <td>0.08</td>
      <td>1.38</td>
      <td>24.68</td>
      <td>30.82</td>
      <td>40.92</td>
    </tr>
  </tbody>
</table>
</div>

- *RAM allocation measurements are over-approximations*
    - *Search object is serialized then the size of the file is reported here*
- *Measurements were done on an average laptop (Lenovo Y520 with a "medium" HW config)*
- *No GPUs were used, all calculations are made on CPUs*
- *Query speed is measured as the average of 10 queries with the given model*

# The tool

Now that we have the search models, we can build the whole tool. There are 2 different parts:
- RestAPI (FastAPI) - *as the backend* - this allows us to search in the stocks
- Dash client app - *as the frontend*
    - I had to use this to quickly create a shiny frontend (I am more of a backend guy 😉) but ideally this
    should be a React frontend which is responsive and looks much better

<img src="https://github.com/gaborvecsei/Stocks-Pattern-Analyzer/raw/master/art/homepage.png" alt="stock patterns tool" width=640>

## RestAPI

When we start the stock-API, a bunch of stocks (S&P500 and a few additional ones) are downloaded, prepared,
and then we start to build the above mentioned search models.
For each length we would like to investigate, a new model gets created with the appropriate dimensions.
To speed up the process, we can download and create the models in parallel (with `concurrent.futures`).

For the simplicity of this tool, 2X a day (because of the different markets) a background scheduled process
updates both the stock data and then the search models.
In a more advanced (not MVP) version you would only need to download the last values for each stock after market close,
create an extra sliding window which contains the new values and then add it to the search model.
This would save you bandwidth and some CPU power.
In my code, I just re-download everything and re-build the search models 😅. 

After starting the script, the endpoints are visible at `localhost:8001/docs`.

## Client Dash app

I really can't say anything interesting about this, I tried to keep the code at minimum while the site
is usable and looks pretty (as long as you are using a desktop).

Dash is perfect to quickly create frontends if you know how to use `plotly`, but for a production scale app as I mentioned
I would go with Reach, Angular or any other alternative.

# Making trading decisions based on the patters

**Please just don't.** I mean it is really fun to look at the graphs and check what are the most similar
stocks out there and what patterns can you find, but let's be honest:

> **This will only fuel your confirmation bias**.

A weighted ensamble of different forecasting techniques would be my first go-to method 🤫.

My only advice:
**Hold** 💎👐💎👐 

# Demo & Code

You can find a [Demo](https://stock-dash-client.herokuapp.com/), which is deployed to Heroku. Maybe you'll need to wait a few minutes befor the page "wakes up".
- [https://stock-dash-client.herokuapp.com](https://stock-dash-client.herokuapp.com)

You can find the code in my [Stock Pattern Analyzer](https://github.com/gaborvecsei/Stocks-Pattern-Analyzer) GitHub repo:
- [https://github.com/gaborvecsei/Stocks-Pattern-Analyzer](https://github.com/gaborvecsei/Stocks-Pattern-Analyzer)

# References

[1] [Trading Patterns Cheat Sheet](https://www.newtraderu.com/2020/06/15/trading-patterns-cheat-sheet/)

[2] [Benchmarking nearest neighbors](https://github.com/erikbern/ann-benchmarks)

[3] [Scipy cKDTree](https://docs.scipy.org/doc/scipy/reference/generated/scipy.spatial.cKDTree.html)

[4] [Faiss GitHub repository](https://github.com/facebookresearch/faiss)

[5] [Big Lessons from FAISS - Vlad Feinberg](https://vladfeinberg.com/2019/07/18/faiss-pt-2.html)

[6] [What is Sliding Window Algorithm?](https://stackoverflow.com/questions/8269916/what-is-sliding-window-algorithm-examples)

[7] [K-d tree Wikipedia](https://en.wikipedia.org/wiki/K-d_tree)

[8] [Algo Trading Dominates 80% Of Stock Market](https://seekingalpha.com/article/4230982-algo-trading-dominates-80-of-stock-market)

[9] [Algorithmic trading - Wikipedia](https://en.wikipedia.org/wiki/Algorithmic_trading)

🚀🚀🌑
