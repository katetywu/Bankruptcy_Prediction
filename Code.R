# Setting up
knitr::opts_chunk$set(echo = F, warning = F, message = F, cache = T)
setwd("/Users/Kate/Desktop/Bankruptcy_Prediction/Data/")

library(tseries)
library(forecast)
library(tidyverse)
library(magrittr)
library(corrplot)
library(vars)
library(car)
library(timetk)
library(gridExtra)
library(scales)
library(Metrics)


# Loading datasets
dataTrain <- read.csv('train.csv', header = TRUE)
dataTest <- read.csv('test.csv', header = TRUE)

# Extracting variables
dataTrain %<>% na.omit()
bankTrain <- ts(dataTrain$Bankruptcy_Rate, start = c(1987, 1), end = c(2014, 12), frequency = 12)
ueTrain <- ts(dataTrain$Unemployment_Rate, start = c(1987, 1), end = c(2014, 12), frequency = 12)
popTrain <- ts(dataTrain$Population, start = c(1987, 1), end = c(2014, 12), frequency = 12)
hpiTrain <- ts(dataTrain$House_Price_Index, start = c(1987, 1), end = c(2014, 12), frequency = 12)

ueTest <- ts(dataTest$Unemployment_Rate, start = c(2015, 1), end = c(2017, 12), frequency = 12)
popTest <- ts(dataTest$Population, start = c(2015, 1), end = c(2017, 12), frequency = 12)
hpiTest <- ts(dataTest$House_Price_Index, start = c(2015, 1), end = c(2017, 12), frequency = 12)

# Validating each variable from train data into training and validation sets, respectively
bankTrainSet <- window(bankTrain, start = c(1987, 1), end = c(2012, 12))
ueTrainSet <- window(ueTrain, start = c(1987, 1), end = c(2012, 12))
popTrainSet <- window(popTrain, start = c(1987, 1), end = c(2012, 12))
hpiTrainSet <- window(hpiTrain, start = c(1987, 1), end = c(2012, 12))

bankValSet <- window(bankTrain, start = c(2013, 1), end = c(2014, 12))
ueValSet <- window(ueTrain, start = c(2013, 1), end = c(2014, 12))
popValSet <- window(popTrain, start = c(2013, 1), end = c(2014, 12))
hpiValSet <- window(hpiTrain, start = c(2013, 1), end = c(2014, 12))

# Visualizing dataset
dfBank <- tk_tbl(bankTrain)
dfUe <- tk_tbl(ueTrain)
dfPop <- tk_tbl(popTrain)
dfHpi <- tk_tbl(hpiTrain)
f1 <- ggplot(dfBank, aes(x = index, y = value)) + geom_line() + xlab('Year') + ylab('Bankruptcy Rate (%)')
f2 <- ggplot(dfUe, aes(x = index, y = value)) + geom_line() + xlab('Year') + ylab('Unemployment Rate (%)')
f3 <- ggplot(dfPop, aes(x = index, y = value)) + geom_line() + xlab('Year') + ylab('Population (million)')
f4 <- ggplot(dfHpi, aes(x = index, y =value)) + geom_line() + xlab('Year') + ylab('House Price Index (%)')
grid.arrange(f1, f2, f3, f4)

par(mfrow = c(1, 1))
corr <- cor(data.frame(dataTrain)[2:5])
corrplot(corr, order = 'hclust', addCoef.col= 'white', type = 'upper', tl.col = 'black', 
         tl.srt = 30, tl.cex = 0.9)

lagCorr <- c()
h = 50

for (i in (seq(h))) {
  lagHpi <- lag(dataTrain$House_Price_Index, n = i)
  iCorr <- cor(lagHpi, dataTrain$Bankruptcy_Rate, use = 'complete.obs')
  lagCorr <- c(lagCorr, iCorr)
}

bestIndex <- which.max(lagCorr)
plot(lagCorr, ylab = 'Lagged Correlation')
points(bestIndex, lagCorr[bestIndex], col = 'red')
title(paste('Best Lag', bestIndex))

# Transforming dataset
transformBoxCox <- function(df, var) {
  lambdaBoxCox <- BoxCox.lambda(df)
  transform <- BoxCox(var, lambda = lambdaBoxCox)
  return(transform)
}

bankTrainSetTrans <- transformBoxCox(bankTrainSet, bankTrainSet)
ueTrainSetTrans <- transformBoxCox(bankTrainSet, ueTrainSet)
popTrainSetTrans <- transformBoxCox(bankTrainSet, popTrainSet)
hpiTrainSetTrans <- transformBoxCox(bankTrainSet, hpiTrainSet)

bankValSetTrans <- transformBoxCox(bankTrainSet, bankValSet)
ueValSetTrans <- transformBoxCox(bankTrainSet, ueValSet)
popValSetTrans <- transformBoxCox(bankTrainSet, popValSet)
hpiValSetTrans <- transformBoxCox(bankTrainSet, hpiValSet)

# Checking stationariness
adf.test(bankTrainSetTrans)
ndiffs(bankTrainSetTrans)
nsdiffs(bankTrainSetTrans)

acf(diff(diff(bankTrainSetTrans), lag = 12), main = 'Bankruptcy Rate (d=1, D=1, lag=12)', lag.max = 60, ylim = c(-1, 1))
pacf(diff(diff(bankTrainSetTrans), lag = 12), main = 'Bankruptcy Rate (d=1, D=1, lag=12)', lag.max = 60, ylim = c(-1, 1))

# SARIMA model
for (p in 1:3) {
  for (q in 1:3) {
    for (P in 1:2) {
      for (Q in 1:4) {
        tryCatch({
          model <- arima(bankTrainSetTrans,
                              order = c(p, 1, q),
                              seasonal = list(order = c(P, 1, Q),
                                              period = 12),
                              method = 'CSS')
          pred <- forecast(model, h = 24, level = 0.95)
          rmse <- rmse(bankValSetTrans, pred$mean)
          print(paste(p, q, P, Q, rmse))
          error = function(e) {
            cat('Error :', conditionMessage(e), '\n')
          }
        })
      }
    }
  }
}

bestSARIMA <- arima(bankTrainSetTrans, order = c(2, 1, 2),
                    seasonal = list(order = c(2, 1, 3),
                                    period = 12),
                    method = 'CSS')
predSARIMA <- forecast(bestSARIMA, level = 0.95, h =24)
rmseSARIMA <- rmse(bankValSetTrans, predSARIMA$mean)

# timeNew <- seq(2013, 2015, length = 25)[1:24]
# plot(bankTrain, xlim = c(1987, 2015), ylim = c(0, 10),
#      main = expression('SARIMA (2,1,2)(2,1,3)'[12]* '(RMSE = 0.09183)'),
#      ylab = 'Bankruptcy Rate')
# abline(v = 2013, col = '#2EA9DF', lty = 2)
# lines(exp(fitted(bestSARIMA))~seq(1987, 2013, length = 313)[1:312], 
#       type = 'l', col = '#EFBB24')
# lines(exp(predSARIMA$mean)~timeNew, type = 'l', col = '#CB4042')
# lines(exp(predSARIMA$lower)~timeNew, col = '#86C166')
# lines(exp(predSARIMA$upper)~timeNew, col = '#86C166')
# legend('topleft', legend = c('Predicted', 'Fitted', 'Lower/Upper 95% CI', 'Actual'), 
#        col = c('#CB4042', '#EFBB24', '#86C166', 'black'), lty = 1)

# SARIMAX model
for (p in 1:3) {
  for (q in 1:3) {
    for (P in 1:2) {
      for (Q in 1:4) {
        tryCatch({
          model <- Arima(bankTrainSetTrans,
                         order = c(p, 1, q),
                         seasonal = list(order = c(P, 1, Q),
                                         period = 12),
                         method = 'CSS',
                         xreg = unlist(popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans))
          pred <- forecast(model, h = 24, level = 0.95,
                           biasadj = TRUE,
                           xreg = unlist(popValSetTrans, hpiValSetTrans, ueValSetTrans))
          rmse <- rmse(bankValSetTrans, pred$mean)
          print(paste(p, q, P, Q, rmse))
          error = function(e) {
            cat('Error :', conditionMessage(e), '\n')
          }
        })
      }
    }
  }
}

bestSARIMAX <- Arima(bankTrainSetTrans,
                     order = c(1, 1, 2),
                     seasonal = list(order = c(2, 1, 2), period = 12),
                     method = 'CSS',
                     xreg = unlist(popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans))
predSARIMAX <- forecast(bestSARIMAX, h = 24, level = 0.95,
                        xreg = unlist(popValSetTrans, hpiValSetTrans, ueValSetTrans))

# plot(bankTrain, xlim = c(1987, 2015), ylim = c(0, 10),
#      main = expression('SARIMAX (1,1,2)(2,1,2)'[12]* '(RMSE = 0.07617)'),
#      ylab = 'Bankruptcy Rate')
# abline(v = 2013, col = '#2EA9DF', lty = 2)
# lines(exp(fitted(bestSARIMAX))~seq(1987, 2013, length = 313)[1:312], 
#       type = 'l', col = '#EFBB24')
# lines(exp(predSARIMAX$mean)~timeNew, type = 'l', col = '#CB4042')
# lines(exp(predSARIMAX$lower)~timeNew, col = '#86C166')
# lines(exp(predSARIMAX$upper)~timeNew, col = '#86C166')
# legend('topleft', legend = c('Predicted', 'Fitted', 'Lower/Upper 95% CI', 'Actual'), 
#        col = c('#CB4042', '#EFBB24', '#86C166', 'black'), lty = 1)

# Holt-Winters' seasonal model
if(T) {
  rmseValue <- c()
  alphaValue <- c()
  betaValue<- c()
  gammaValue <- c()
  for (alpha in seq(0.1, 0.9, 0.1)) {
    for (beta in seq(0.1, 0.9, 0.1)) {
      for (gamma in seq(0.1, 0.9, 0.1)) {
        model <- HoltWinters(bankTrainSetTrans, alpha = alpha,
                             beta = beta, gamma = gamma,
                             seasonal = 'multiplicative')
        pred <- forecast(model, h = 72, level = 0.95)
        rmse <- sqrt(mean((pred$mean - bankValSetTrans)^2))
        rmseValue <- c(rmseValue, rmse)
        alphaValue <- c(alphaValue, alpha)
        betaValue <- c(betaValue, beta)
        gammaValue <- c(gammaValue, gamma)
      }
    }
  }
  data.frame(alphaValue, betaValue, gammaValue, rmseValue)
  index <- which(rmseValue == min(rmseValue))
  cat (alphaValue[index], betaValue[index], gammaValue[index])
}

bestHoltWinters <- HoltWinters(bankTrainSetTrans, alpha = 0.2,
                               beta = 0.6, gamma = 0.1,
                               seasonal = 'multiplicative')
predHoltWinters <- forecast(bestHoltWinters, level = 0.95, h = 24)
rmseHoltWinters <- rmse(bankValSetTrans, predHoltWinters$mean)

# plot(bankTrain, xlim = c(1987, 2015), ylim = c(0, 10),
#      main = expression('Holt-Winters (RMSE = 0.11913)'),
#      ylab = 'Bankruptcy Rate')
# abline(v = 2013, col = '#2EA9DF', lty = 2)
# lines(exp(fitted(bestHoltWinters)[,1])~seq(1987, 2013, length = 300), 
#       type = 'l', col = '#EFBB24')
# lines(exp(predHoltWinters$mean)~timeNew, type = 'l', col = '#CB4042')
# lines(exp(predHoltWinters$lower)~timeNew, col = '#86C166')
# lines(exp(predHoltWinters$upper)~timeNew, col = '#86C166')
# legend('topleft', legend = c('Predicted', 'Fitted', 'Lower/Upper 95% CI', 'Actual'), 
#        col = c('#CB4042', '#EFBB24', '#86C166', 'black'), lty = 1)

# VAR model
if (T) {
  rmseValue <- c()
  pValue <- c()
  for (p in seq(1, 10, 1)) {
    model <- VAR(data.frame(bankTrainSetTrans, popTrainSetTrans, hpiTrainSetTrans),
                 p = p, season = 12, ic = 'AIC')
    pred <- predict(model, n.ahead = 24, ci = 0.95, biasadj = TRUE)
    rmse <- sqrt(mean(pred$fcst$bankTrainSetTrans[,1] - bankValSetTrans)^2)
    rmseValue <- c(rmseValue, rmse)
    pValue <- c(pValue, p)
  }
  data.frame(rmseValue, pValue)
  index <- which(rmseValue == min(rmseValue))
  cat (pValue[index], rmseValue[index])
}








