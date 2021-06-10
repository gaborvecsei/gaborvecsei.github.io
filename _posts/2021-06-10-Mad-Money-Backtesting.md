---
title: "Bactesting Mad-Money recommendations and the Cramer-effect"
subtitle: "Can we profit from the stock picking guru?"
layout: post
date: 2021-06-10 00:00
tag:
  - Stocks
  - Finance
  - Python
  - Backtesting
headerImage: false
description: ""
category: blog
author: gaborvecsei
externalLink: false
---

When it comes to trading, investors are listening a lot on other people opinions without looking into the data and 
the background of the company. And the more credible (at least in theory) the source the more people pay attention
without any second thought. This is the case with the show *Mad Money* on CNBC *[1]* with the host *Jim Cramer*.
*It is funny how this is not a problem for the SEC or anyone, but people talkig on forums suggesting stocks is bad and
should be punished.*
In this post I will show you how the "Mad Money" portfolio could have performerd and what the Cramer effect looks like.

To achieve this I scraped the historical buy recommendations from the show, then backtested every company which was
on the list as a "buy recommendation".

Find the GitHub repo with all the code and data used to write this post:
[https://github.com/gaborvecsei/Mad-Money-Backtesting](https://github.com/gaborvecsei/Mad-Money-Backtesting}

<img src="https://raw.githubusercontent.com/gaborvecsei/Mad-Money-Backtesting/master/art/cramer.gif" width="400" alt="Cramer"></a>

# The Cramer effect and his recommendations

**The Cramer Effect (Cramer Bounce)**: 
After the show Mad Money the recommended stocks are bought by viewers almost immediately (afterhours trading)
or on the next day at market open, increasing the price for a short period of time. *[4]*

This is really interesting but not surprising as I already pointed out in the intro how this works for most people.

Other that this I wanted to take a bigger timeframe and see what would have happened if I follow the investment ideas
of the stock picking guru.

# Recommendations data from the show

Fortunately the data is available, as Cramer's team make it available via their own website *[2]*, we just need
to get the data from there.

You can find a table on the site which holds the mentioned stocks and actions on the show for a single day. As you can see
there are some basic options where we can select a price threshold, and most importantly the day, when there was a show.
If we look closed and investigate the requests being made (via browser dev mode), we can see that a simple POST
request is sent with some form data (`application/x-www-form-urlencoded`) which contains the different "filterings".
This can be easily constructed, so once we have the contents of the page, we only need to parse it. I used
`BeautifulSoup` for that.

You can do this for yourself with [this little script](https://github.com/gaborvecsei/Mad-Money-Backtesting/blob/master/scrape_mad_money.py).

## Automation w/ GitHub Actions

Let's be honest, we can do much better than manually preparing the data. Even better, as the resultsing file is
not huge, we can keep it in the version control system. This is not just a fancy addition, but can actually help as
it can be directly used by everyone and more importantly, we can see the change in the contents of the file over time.
Maybe you think it's not a big deal, but this way, if there would be a problem on the Mad Money crew's end, and they
would mess up recommendations for some dates (in the present everyone if smarter about the past 😉) then we would see it.
We can get rid of the "it's working on my computer" but for data problem.

Also, with the Flat Data Viewer *[3]*, we get a cool visualization:
[https://flatgithub.com/gaborvecsei/Mad-Money-Backtesting](https://flatgithub.com/gaborvecsei/Mad-Money-Backtesting)

This is all achieved with *GitHub Actions*. Without going into the details it's just this simple:
- Setup the workflow
- Prepare Python with the necessary dependencies
- Use the scraper code to get and transform the data
- If there was a change in the contents then let's commit it
- Enjoy the fruits of this really cool feature

# Backtesting

As everything is covered, what is the goal, how we got the data, we can start to look into the backtesting and
the results.

For the backtesting I used the `backtesting.py` *[5]* package (The `backtrader` is just as good)
and `yfinance` *[6]* with which I got the historical stock data.

For the simulations, each mentioned stock is tested individually, then the overall results are calculated.
(We also store the individual results in a html file.)
I have a predefined amount which I would invest in a stock. This stays the same no matter the price, as we want to
spend equally as we don't know how the stock will perform.
At each buy recommendation we go "all in" and buy as many positions as we can with the money. Once we sell, then we sell all of it.
The buy and sell dates are defined in the backtesting classes, and they are "calculated" from the recommendation dates.
This is repeated if a company was mentioned more times.

(Also, a commissing is set: $2%$.)

## Challenges

Before I show the results, I would like to write a bit about the challenges. These are important factors as all of
them can alter the results at the end.

Fortunately if you have better data, then it is easily curable.

### After hours data

This is one of the biggest problems 😢 as we literally don't have it. It's a bit of an over exaggeration,
as `Yfinance` can provide it but it is sparse. I "solved" this by stating that the price at showtime is the same as
it is at market close. Of course this way we cannot test with high accuracy the "after the show" after-hours volatility.

If you have (maybe a paid) data resource, then by adjusting the buy/sell date calculations, you can easily adapt the
strategies to a propre after-hours trading session which would provide the accurate results for the Cramer effect.

### Missing days

There are a few days for each stock, where we have missing data. There is a function with which you can transform them.
Either you drop it, or use the next "closest" date.

Dropping would mean, that we won't buy/sell on the date at all, while using the closest date could result in lower
accuracy in returns, as that is also an approximation. Btw. if in the real-life scenario we would not stirictly follow
the buy patterns, and would buy max 1 business day later, than that would match with this approximation.

## Trading Strategies

Multiple trading strategies are implemented to test the Cramer effect and his "portfolio":
- A) *BuyAndHold* (and repeat)
  - The stocks are bought at the first mention on the show, then held for $N$ days. On the $N$th day the positions are 
  closed. If there were other mentions after we sold, we repeat this process
- B) *AfterShowBuyNextDayCloseSell*
  - We buy the mentioned stocks at the end of the show and then sell on the next day at market Close
- C) *AfterShowBuyNextDayOpenSell*
  - We buy the mentioned stocks at the end of the show and then sell on the next day at market Open
- D) *NextDayOpenBuyNextDayCloseSell*
  - We buy the mentioned stocks at next day market open and then sell it on the same day at market close

The Cramer-effect is simulated with strategies *B, C* and *D*, as we are aiming for the short-term effect.
Stretegy *D* is the one, where no after-hours trading is involved.

## Results

### Buy and Hold

TODO

### Cramer Effect

TODO

# Conclustion

# References

[1] [Mad Money show](https://en.wikipedia.org/wiki/Mad_Money)

[2] [Mad Money screener](https://madmoney.thestreet.com/screener)

[3] [GitHub Flat Data Viewer](https://octo.github.com/projects/flat-data)

[4] [The Cramer Effect](https://www.investopedia.com/terms/c/cramerbounce.asp#:~:text=The%20Cramer%20bounce%20refers%20to%20the%20increase%20in%20a%20stock's,Jim%20Cramer's%20show%20Mad%20Money.&text=Research%20has%20shown%20an%20average,the%20effect%20is%20short%2Dlived.)

[5] [Backtraing.py repo](https://github.com/kernc/backtesting.py)

[6] [Yahoo Finance API](https://github.com/ranaroussi/yfinance)

<img src="https://github.com/gaborvecsei/Stocks-Pattern-Analyzer/raw/master/art/homepage.png" alt="stock patterns tool" width=640>
