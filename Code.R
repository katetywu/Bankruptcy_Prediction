# Setting up
knitr::opts_chunk$set(echo = F, warning = F, message = F, cache = T)
setwd("/Users/Kate/Desktop/bankruptcy-rate-prediction/Data/")

library(tseries)
library(forecast)
library(tidyverse)
library(magrittr)
library(corrplot)
library(vars)
library(car)
library(timetk)
library(Metrics)
library(gridExtra)


# Loading datasets
dataTrain <- read.csv('train.csv', header = TRUE)
dataTest <- read.csv('test.csv', header = TRUE)


# Extracting variables
dataTrain %<>% na.omit()
train <- ts(dataTrain, start = c(1987, 1), frequency = 12)
bankTrain <- ts(dataTrain$Bankruptcy_Rate, start = c(1987, 1), frequency = 12)
ueTrain <- ts(dataTrain$Unemployment_Rate, start = c(1987, 1), frequency = 12)
popTrain <- ts(dataTrain$Population, start = c(1987, 1), frequency = 12)
hpiTrain <- ts(dataTrain$House_Price_Index, start = c(1987, 1), frequency = 12)

test <- ts(dataTest, start = c(2015, 1), frequency = 12)
ueTest <- ts(dataTest$Unemployment_Rate, start = c(2015, 1), frequency = 12)
popTest <- ts(dataTest$Population, start = c(2015, 1), frequency = 12)
hpiTest <- ts(dataTest$House_Price_Index, start = c(2015, 1), frequency = 12)


# Validating each variable from train data into training and validation sets, respectively
bankTrainSet <- window(bankTrain, start = c(1987, 1), end = c(2012, 12), frequency = 12)
ueTrainSet <- window(ueTrain, start = c(1987, 1), end = c(2012, 12), frequency = 12)
popTrainSet <- window(popTrain, start = c(1987, 1), end = c(2012, 12), frequency = 12)
hpiTrainSet <- window(hpiTrain, start = c(1987, 1), end = c(2012, 12), frequency = 12)

bankValSet <- window(bankTrain, start = c(2013, 1), end = c(2014, 12), frequency = 12)
ueValSet <- window(ueTrain, start = c(2013, 1), end = c(2014, 12), frequency = 12)
popValSet <- window(popTrain, start = c(2013, 1), end = c(2014, 12), frequency = 12)
hpiValSet <- window(hpiTrain, start = c(2013, 1), end = c(2014, 12), frequency = 12)


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

lambdaValue <- BoxCox.lambda(bankTrainSet)

bankTrainTrans <- transformBoxCox(bankTrainSet, bankTrain)
hpiTrainTrans <- transformBoxCox(bankTrainSet, hpiTrain)
popTrainTrans <- transformBoxCox(bankTrainSet, popTrain)
ueTrainTrans <- transformBoxCox(bankTrainSet, ueTrain)

hpiTestTrans <- transformBoxCox(bankTrainSet, hpiTest)
popTestTrans <- transformBoxCox(bankTrainSet, popTest)
ueTestTrans <- transformBoxCox(bankTrainSet, ueTest)

bankTrainSetTrans <- transformBoxCox(bankTrainSet, bankTrainSet)
hpiTrainSetTrans <- transformBoxCox(bankTrainSet, hpiTrainSet)
popTrainSetTrans <- transformBoxCox(bankTrainSet, popTrainSet)
ueTrainSetTrans <- transformBoxCox(bankTrainSet, ueTrainSet)

bankValSetTrans <- transformBoxCox(bankTrainSet, bankValSet)
hpiValSetTrans <- transformBoxCox(bankTrainSet, hpiValSet)
popValSetTrans <- transformBoxCox(bankTrainSet, popValSet)
ueValSetTrans <- transformBoxCox(bankTrainSet, ueValSet)


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
                         seasonal = list(order = c(P, 1, Q), period = 12),
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


# SARIMAX model
for (p in 1:3) {
  for (q in 1:3) {
    for (P in 1:2) {
      for (Q in 1:4) {
        tryCatch({
          model <- Arima(bankTrainSetTrans,
                         order = c(p, 1, q),
                         seasonal = list(order = c(P, 1, Q), period = 12),
                         method = 'CSS', 
                         xreg = as.matrix(popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans))
          pred <- forecast(model, h = 24, level = 0.95,
                           lambda = lambdaValue, biasadj = TRUE,
                           xreg = as.matrix(popValSetTrans, hpiValSetTrans, ueValSetTrans))
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
                     order = c(1, 1, 1),
                     seasonal = list(order = c(1, 1, 1), period = 12),
                     method = 'CSS',
                     xreg = as.matrix(popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans))
predSARIMAX <- forecast(bestSARIMAX, h = 24, level = 0.95, 
                        lambda = lambdaValue, biasadj = TRUE,
                        xreg = as.matrix(popValSetTrans, hpiValSetTrans, ueValSetTrans))

rmseSARIMAX <- rmse(bankValSetTrans, predSARIMAX$mean)


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
        pred <- forecast(model, h = 60, level = 0.95)
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


# VAR model
if (T) {
  rmseValue <- c()
  pValue <- c()
  for (p in seq(1, 10, 1)) {
    model <- VAR(data.frame(bankTrainSetTrans, popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans),
                 p = p, season = 12, ic = 'AIC')
    forecast <- predict(model, n.ahead = 24, ci = 0.95, biasadj = TRUE)
    pred <- forecast$fcst$bankTrainSetTrans[,1]
    predTransBack <- exp(log(lambdaValue * pred + 1) / lambdaValue)
    rmse <- rmse(predTransBack, bankValSetTrans)
    rmseValue <- c(rmseValue, rmse)
    pValue <- c(pValue, p)
  }
  data.frame(rmseValue, pValue)
  index <- which(rmseValue == min(rmseValue))
  cat (pValue[index], rmseValue[index])
}


# Final Model & Prediction
finalModel <- Arima(bankTrainSetTrans,
                     order = c(1, 1, 1),
                     seasonal = list(order = c(1, 1, 1), period = 12),
                     method = 'CSS',
                     xreg = as.matrix(popTrainSetTrans, hpiTrainSetTrans, ueTrainSetTrans))
finalForecast <- forecast(finalModel, h = 60, level = 0.95, 
                          lambda = lambdaValue, biasadj = TRUE,
                        xreg = as.matrix(popTestTrans, hpiTestTrans, ueTestTrans))

finalPred <- data.frame(prediction = unclass(finalForecast$mean),
                        lower = unclass(finalForecast$lower[,1]),
                        upper = unclass(finalForecast$upper[,1]))

ts(finalPred$prediction[1:36], start = c(2015, 1), frequency = 12)

newYear <- seq(1987, 2018, length = 373)[1:372]

finalPred %>% 
  ggplot() +
  geom_ribbon(aes(x = newYear[337:372], ymin = lower, ymax = upper), alpha = 0.2) +
  geom_line(aes(x = newYear[337:372], y = prediction, color = "Predicted Values"), size = 0.5) +
  geom_line(data = data.frame(br = bankTrain), aes(x = newYear[1:336], y = br, color = "Actual Values"), size = 0.5) +
  geom_vline(xintercept = 2015, linetype = 'dotted') +
  scale_x_continuous(breaks = seq(1987, 2018, by = 5), limits = c(1987, 2018)) +
  xlab("\nYear") +
  ggtitle('Monthly Bankruptcy Rate in Canada') +
  ylab("Bankruptcy Rate %\n") +
  theme(plot.title=element_text(size=18,face="bold",vjust=2, hjust=0.5)) +
  theme(axis.text.x=element_text(size=12,vjust=0.5,face="bold")) +
  theme(axis.text.y=element_text(size=12,vjust=0.5,face="bold")) +
  theme(axis.title.x=element_text(size=13,vjust=0.5,face="bold"), axis.title.y=element_text(size=13,vjust=0.5,face="bold")) + 
  theme(legend.title=element_blank())

