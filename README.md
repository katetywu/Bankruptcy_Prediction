# Time series forecast using SARIMAX mdoel

## Abstract
The purpose of this project is to predict Canadian national bankrupty rate by using the relevant data from January 1987 to December 2010. The avaialbe dataset includes bankruptcy rate, unemployment rates, house price index, and population. 

## Introduction
A time-series is a sequence of observations of variables taken at a regular time intervlas and it can be decomposed into *a trend, a seasonal (or a cyclical), and an irregular component. The trend component is the long-term behavior of the series and the cyclical component is the regular periodic movements. The irregular component is stochastic and the goal is to estimate and forecast this component.*

## Methods
### * Step 1: Visualizing the dataset
Before applying time series methodology to forecast, I first need to take a look at each variable in the dataset. We can tell that those time components are in each graph.

<p float="left">
    <img src="https://github.com/katetywu/Bankruptcy_Prediction/blob/master/Figures/Figure2.jpeg" width="250" />
    <img src="https://github.com/katetywu/Bankruptcy_Prediction/blob/master/Figures/Figure3.jpeg" width="250" />
    <img src="https://github.com/katetywu/Bankruptcy_Prediction/blob/master/Figures/Figure4.jpeg" width="250" />
</p>

According to the correlation heatmap, it seems that the bankruptcy rate has a negative correlation with the unemployment rate; while has a positive correlation with the house price index. I will take the unemployment rate and the house price index into account in later analysis.

<p float="center">
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure6.jpeg" width="450" />
</p>

### * Step 2: Transforming the series and differencing
The main series `bankruptcy rate` has conspicuous volatilities and it may have high skewed distributions that I transformed it into the logarithm. The rule-of-thumb before building the optimal model is to ensure whether or not the series is stationary, which *the mean, variance, and autocorrelations can be well approximated by sufficiently long time averages based on the single set of realizations.* The Augmented Dickey-Fuller test (ADF) can detect stationarity, and in this case, I failed to reject the null hypothesis that the series is non-stationary. Under this situation the difference equation, *expressing the value of a variable as a function of its own lagged values, time, and other variables* can fix the issue. Only the trend differencing is needed in this case.

<p float="left">
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure8.jpeg" width="400" />
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure10.jpeg" width="400" />
</p>

### * Stpe 3: Observing ACF and PACF
The autocorrelation function (ACF) measures the correlation between series values directly, and it is influenced by the intermediate lags; the partial autocorrelation function (PACF) also measures the correlation between series values, but with the intermediate lags being controlled (i.e. holding the intermidate lags constant). Both the ACF and the PACF can determine the order of processes in an ARMA(p,q) model. ACF begins to decay after lag *q* and PACF begins to decay after lag *p*. The order for each is 5 and 6, respectively.

<p float="left">
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure13.jpeg" width="400" />
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure14.jpeg" width="400" />
</p>

### * Step 4: Building SARIMAX model
Most time-series analyses are univariate that applies historical data of its own to forecast the future. However, I put other time-series into consideration due to their potential correlations with the bankruptcy rate. An ARIMAX model is the ARIMA pluses exogenous explanatory variables. Based on the result of ADF test, the seasonal differecing is unnecessary; yet there is a decreasingly positive spike between lags. These spikes determine the order of *P*. The following table depicts the combination of *p, q, d, P*; and by comparing the Akaike Information Criterion (AIC) - an estimator examines the relative amount of information lost by a given model. SARIMAX(4,1,5)(1,0,0)[12] has the smallest score that I will use it to do the prediction.

MODEL | LOGLIK | AIC
--- | --- | --- |
SARIMAX(1,1,1)(1,0,0)[12] | 322.7757 | -653.5514
SARIMAX(1,1,2)(1,0,0)[12] | 337.9108 | -661.8216
SARIMAX(1,1,3)(1,0,0)[12] | 346.1099 | -676.2198
SARIMAX(1,1,4)(1,0,0)[12] | 346.2825 | -674.5650
SARIMAX(1,1,5)(1,0,0)[12] | 352.7679 | -685.5357
SARIMAX(2,1,1)(1,0,0)[12] | 343.3811 | -672.7621
SARIMAX(2,1,2)(1,0,0)[12] | 346.9254 | -677.8508
SARIMAX(2,1,3)(1,0,0)[12] | 346.9545 | -675.9089
SARIMAX(2,1,4)(1,0,0)[12] | 367.2904 | -714.5808
SARIMAX(2,1,5)(1,0,0)[12] | 369.8277 | -717.6555
SARIMAX(3,1,1)(1,0,0)[12] | 346.6656 | -677.3312
SARIMAX(3,1,2)(1,0,0)[12] | 346.9773 | -675.9546
SARIMAX(3,1,3)(1,0,0)[12] | 348.0559 | -676.1119
SARIMAX(3,1,4)(1,0,0)[12] | 349.3335 | -676.6669
SARIMAX(3,1,5)(1,0,0)[12] | 372.4272 | -720.8544
SARIMAX(4,1,1)(1,0,0)[12] | 348.5848 | -679.1707
SARIMAX(4,1,2)(1,0,0)[12] | 352.0183 | -684.0365
SARIMAX(4,1,3)(1,0,0)[12] | 368.9054 | -715.8108
SARIMAX(4,1,4)(1,0,0)[12] | 372.6625 | -721.3250
SARIMAX(4,1,5)(1,0,0)[12] | 376.2098 | -726.4197

Once the model is decided, I have to ensure whether or not model residuals have zero mean, constant variance, and normal distribution over time. The following graph shows that the model is qualified for all criteria and is ready to do the forecasting.

<p float="center">
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure15.jpeg" width="400" />
</p>

### * Step 5: Forecasting
Adding the exogenous covariates, which are unemployment rate and house price index, into the model; I predict the trend for the next 24 months. The result lies in a 95% confidence interval. 

<p float="center">
    <img src="https://github.com/katetywu/bankruptcy/blob/master/Figures/Figure18.jpeg" width="400" />
</p>

## Summary
With all time-factor components controlled, SARIMAX(4,1,5)(1,0,0)[12] is the optimal model to forecast the bankruptcy rate in this case. Based on the result of the model, the rate will decreasee in the next 2 years.
