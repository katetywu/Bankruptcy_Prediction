# Canada Bankruptcy Prediction

## ME in this project
* Role: Economics researcher, Data analyst
* Tool: RStudio
* Duration: 1 week

## Introduction
> Nothing is more unpredictable than the financial market.

Bankruptcy is a leagal process overseen by federal bankruptcy courts to allow individuals or businesses freedom from their debts, while simultaneously providing creditors an opportunity for repayment.

The concept of time series is applied into the project. A time series a sequence of observations of variables taken at a regular time intervals and it can be decomposed into a trend, a seasonal (or a cyclical), and an irregular component. The trend component is the long-term behavior of the series; the cyclical component is the regularly periodic movements, and the irregular component is stochastic. The goal is to estimate and forecast the untypical elements. 

In this project, I would like to control the irregularity, narrow biases, and get the result as accurate as possible. After these steps, I then could conclude the trend for the bankruptcy rate in the upcoming two years.

## Data & Variables
From 1980 to 2017, monthly country-level data including the unemployment rate, the bankrtupcy rate, and the house price index is used in the project. [Statistics Canada](https://www.statcan.gc.ca/eng/start) and [Federal Reserve Economic Data (FRED)](https://fred.stlouisfed.org/) are the main database.

## Hypothesis
Take the situation of the Canadian financial market in 2015 into consideration, I assume that the bankruptcy rate will decrease in the following years. To prove this statement, I will use the autoregressive moving average (ARMA) model to figure out the optimal model.

## Results
Based on the "eye-ball" test of the following figures, we have an increasing trend in both the bankruptcy rate and the house price index; a decreasing tendency in the unemployment rate. Though the directions of these three variables are opposite, I believe there might be a relationsip among them. The bankruptcy rate has a postive and a negative connection with the house price index and the unemployment rate, respectively. Having a quick overview of three variables, I also minimize the skewness in the bankruptcy rate by using the logarithm function.

![Bankruptcy rate](https://github.com/katetywu/Bankruptcy_Prediction/blob/master/Figures/bankruptcyRate.jpeg "title-1") ![alt-text-2](https://github.com/katetywu/Bankruptcy_Prediction/blob/master/Figures/bankruptcyRate.jpeg "title-2")

> Stationary indicates that the mean, variance, and autocorrelations are well approximated by sufficiently long time averages based on the single set of realizations.

I have to ensure that the time series - `bankruptcy rate` is stationary. There are several ways to detect whether or not the staionariness exists, I choose the Augmented Dickey-Fuller test (ADF) and fail to reject the null hypothesis, which the bankruptcy rate is stationary. Under this situation, I use the difference equation to eliminate *noises* from the variable. The difference equation is the funcation *expressing the value of a variable by its own lagged values, time, and other factors*; in other words, I take an one-year lag of the bankruptcy rate to remove the trend element.

Not until finishing the data transformation process can I start to build a model. There are two directions to build the time seires model. One is the univariate model that has one dependent variable and its historical data; the other is the multivairate model that takes one dependent variables, other independent variables, and the historical data. Most of times, the multivariate model is used more often in the financial market in terms of the possible correlations, comprehensive factors, and realistic picture about the real world. The challenging parts for this type of method are complex statistics and arcane interpretations invovled. After reviewing all conditions carefully, I decide to use this method and I am prepared to set up my ARMA model.

> Autoregressive Moving Average (ARMA) Model is used to describe wearkly stationary stochastic time series in terms of two polynomials. One is called AR and the other is called MA.

The AR involves regressing the variable on its own lagged/past values, the MA involves modeling the error term as a linear combination which occurs contemporaneously at various times in the past. The model is referred to as the ARMA(p, q) where the p is the order of the AR and the q is the order of the MA. The autocorrelation function (ACF) measures the correlation between series values directly and is influenced by the intermediate values; in other words, __the ACF describes the autocorrelation between an observation and another observation at a prior time step including direct and indirect dependence information.__ The partial autocorrelation function (PACF) also measures the correlation between series values but with the intermediate lags being controlled; put differently, __the PACF only describes the direct relationship between an observation and its lag, holding the intermediate lags constant.__ The ACF determines the order of MA(q) and the PACF determines the order of AR(p). In this project, the order of *p and q* is 4 and 5, respectively.

> ARIMA is suitable for univariate datasets. ARIMAX is suitable for multivariate datasets.

ARIMAX is used for analyses where there are additional and exogenous explanatory variables. I start building my model with ARIMAX and check the differencing option by the ADF test. According to the ADF test, the seasonal differencing is unnecessary, but based on the PACF plot, there is a decreasingly positive spike between lags. After careful consideration, I decide to take the seasonal differencing and get the order of *P.* With all elements prepared completely, I have several SARIMAX models that I select the optimal one by the comparison using the Akaike Information Criterion (AIC) - an estimator examines the relative amount of information lost by a given model. SARIMAX(4,1,5)(1,0,0)[12] gets the smallest AIC score; other SARIMAX models can be found [here]("..."). There is still one thing to do before making the prediction - the model I chose is align with the White Noise priciple where all variables have the same variance and each value has a zero correlation with all other values. From the figure below, my model meets the criteria that I am prepared for the forecasting step.

## Conclusion & Suggestions
To sum up, SARIMAX(4,1,5)(1,0,0)[12] predicts the bankruptcy rate will decrease in the following years and the forecasting result lies in the 95% confidence interval, which determines how convincing the result is. The economy in Canada could be better in the following years; however, this conclusion could be improved by adding more information such as the GDP, the household income level, the PPP, etc. to the future research.