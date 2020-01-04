setwd("/Users/Kate/Desktop/bankruptcy/Data/")
library(forecast)
library(ggplot2)
library(tseries)
library(lawstat)
library(lmtest)
library(tidyr)
library(dplyr)
library(highcharter)

MainData <- read.csv('dataset.train.canada.csv')
TestData <- read.csv('dataset.test.canada.csv')

MainData$Month <- seq.Date(as.Date("1987/1/1"), as.Date("2010/12/1"), by="month")
TestData$Month <- seq.Date(as.Date("2011/1/1"), as.Date("2012/12/1"), by="month")

### Visualizing series ###
df1 <- MainData %>%
        select (Month, Bankruptcy_Rate, Unemployment_Rate, House_Price_Index) %>%
        gather (key = "Variable", value = "Percentage", -Month)

ggplot(df1, aes(x = Month, y = Percentage)) + geom_line(aes(color = Variable), size = 1) +
  scale_color_manual(values = c("#D0104C", "#F05E1C", "#268785")) +
  theme_minimal()

ggplot(data = MainData, aes(x = Month, y = Bankruptcy_Rate)) + geom_line(color = "#D0104C", size = 1)
ggplot(data = MainData, aes(x = Month, y = Unemployment_Rate)) + geom_line(color = "#F05E1C", size = 1)
ggplot(data = MainData, aes(x = Month, y = House_Price_Index)) + geom_line(color = "#268785", size = 1)
ggplot(data = MainData, aes(x = Month, y = Population)) + geom_line(color = "#6A4C9C", size = 1)

### Visualizing correlation plot ###
corr <- MainData[, c(2,4,5)]
print(hchart(cor(corr)))

### Setting the dataframe ###
BR <- ts(MainData$Bankruptcy_Rate, frequency = 12, start = 1987)
xreg_train <- cbind(MainData$Unemployment_Rate, MainData$House_Price_Index)

### Checking whether the series is stationary ###
adf.test(BR)
ndiffs(BR)
plot(BR, type = "l", main = "Bankruptcy Rate", ylab = "%", xlab = "Month")
lBR <- log(BR)
plot(lBR, type = "l", main = "Log Bankruptcy Rate", ylab ="", xlab = "Month")
dBR <- diff(BR)
plot(dBR, type = "l", main = "Difference Bankruptcy Rate", ylab="", xlab = "Month")
dlBR <- diff(lBR)
plot(dlBR, type = "l", main = "Difference Log Bankruptcy Rate", ylab ="", xlab = "Month")

### Deciding the order of p, q, P ###
acf(BR, main = "ACF of Bankruptcy Rate", lag.max = 60, ylim = c(-0.5,1))
pacf(BR, main = "PACF of Bankruptcy Rate", lag.max = 60, ylim = c(-0.5,1))
acf(dlBR, main = "ACF of Difference Bankruptcy Rate", lag.max = 60, ylim = c(-0.5,1))
pacf(dlBR, main = "PACF of Difference Bankruptcy Rate", lag.max = 60, ylim = c(-0.5,1))
# q<=5, p<=4, P=1

### Building ARIMAX models ###
m11 <- arima(lBR, order = c(1,1,1),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m12 <- arima(lBR, order = c(1,1,2),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m13 <- arima(lBR, order = c(1,1,3),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m14 <- arima(lBR, order = c(1,1,4),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m15 <- arima(lBR, order = c(1,1,5),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m21 <- arima(lBR, order = c(2,1,1),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m22 <- arima(lBR, order = c(2,1,2),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m23 <- arima(lBR, order = c(2,1,3),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m24 <- arima(lBR, order = c(2,1,4),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m25 <- arima(lBR, order = c(2,1,5),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m31 <- arima(lBR, order = c(3,1,1),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m32 <- arima(lBR, order = c(3,1,2),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m33 <- arima(lBR, order = c(3,1,3),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m34 <- arima(lBR, order = c(3,1,4),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m35 <- arima(lBR, order = c(3,1,5),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m41 <- arima(lBR, order = c(4,1,1),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m42 <- arima(lBR, order = c(4,1,2),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m43 <- arima(lBR, order = c(4,1,3),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m44 <- arima(lBR, order = c(4,1,4),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)
m45 <- arima(lBR, order = c(4,1,5),
             seasonal = list(order = c(1,0,0), period = 12),
             xreg = xreg_train)

### Setting a simple table to view results ###
MODEL <- c("m11", "m12", "m13", "m14", "m15",
           "m21", "m22", "m23", "m24", "m25",
           "m31", "m32", "m33", "m34", "m35",
           "m41", "m42", "m43", "m44", "m45")

LOGLIK <- c(m11$loglik, m12$loglik, m13$loglik, m14$loglik, m15$loglik,
            m21$loglik, m22$loglik, m23$loglik, m24$loglik, m25$loglik,
            m31$loglik, m32$loglik, m33$loglik, m34$loglik, m35$loglik,
            m41$loglik, m42$loglik, m43$loglik, m44$loglik, m45$loglik)

AIC <- c(m11$aic, m12$aic, m13$aic, m14$aic, m15$aic,
         m21$aic, m22$aic, m23$aic, m24$aic, m25$aic,
         m31$aic, m32$aic, m33$aic, m34$aic, m35$aic,
         m41$aic, m42$aic, m43$aic, m44$aic, m45$aic)

Table <- data.frame(MODEL, LOGLIK, AIC)
Table
# SARIMA(4,1,5)(1,0,0)[12] has the smallest AIC

### Checking how well is the model ###
summary(m45)
tsdiag(m45)
e45 <- m45$residuals
se45 <- e45/sqrt(m45$sigma2)

# 1. Zero mean
t.test(e45)

# 2. Heteroskedasticity
group <- c(rep(1,72), rep(2,72), rep(3,72), rep(4,72))
levene.test(e45, group)
bartlett.test(e45, group)

# 3. Normality
qqnorm(m45$residuals, main = "Normal QQ-Plot of SARIMA(4,1,5)(1,0,0)[12] Residuals")
qqline(m45$residuals, col = "#C1328E", lty = 1, lwd = 2)

hist(m45$residuals/sqrt(m45$sigma2), freq = FALSE, main = "Histogram of Standardized Residulas with N(0,1) Density Curve", xlab = "")
curve(dnorm, -5,10, add = T, col = "#C1328E", lwd = 2)

### Forecasting ###
xreg_test <- cbind(TestData$Unemployment_Rate, TestData$House_Price_Index)

forecast <- forecast(m45, h = 24, xreg = xreg_test)
accuracy(forecast)

m45 %>%
  forecast(h = 24, xreg = xreg_test, level = 0.95) %>%
  hchart() %>%
  hc_title(text = "Bankruptcy rate and forecast") %>%
  hc_yAxis(title = list(text = "Monthly rate"),
           labels = list(format = "{value}%"),
           opposite = FALSE) %>%
  hc_add_theme(hc_theme_ffx())







