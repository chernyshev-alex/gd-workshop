import sys
import pandas as pd
from fbprophet import Prophet
from os.path import abspath
import matplotlib.pyplot as plt
from datetime import datetime,date

#DATA_DIR = '/data/'
DATA_DIR = '../../data/'
#INPUT_CSV = abspath(DATA_DIR + 'aapl.csv')
INPUT_CSV = abspath(DATA_DIR + 'AAPL_FROM2017.csv')

if (len(sys.argv) < 2):
    print("Usage : {} days".format(sys.argv[0]))
    sys.exit()

predict_days = int(sys.argv[1])

print("read input data " + INPUT_CSV)
csv = pd.read_csv(INPUT_CSV)

df = csv[['Date', 'Close']]
df.rename(columns={'Date' : 'ds', 'Close' : 'y'}, inplace=True)
last = datetime.strptime(df.tail(1)['ds'].values[0],'%Y-%m-%d')
predict_days = (datetime.now() - last).days
#Filter all before 2019
#df = df[df['ds']>'2019-01-01']


cap = 350
floor =  10
df['cap']=cap
df['floor']=floor

print('train model ..')
m = Prophet(weekly_seasonality=True, daily_seasonality=True)
#m = Prophet(growth='logistic',changepoint_prior_scale=1, weekly_seasonality=True, daily_seasonality=True)
m.fit(df)

print("predict for {} days".format(predict_days))
future = m.make_future_dataframe(periods=predict_days)
future['cap']=cap
future['floor']=floor
forecast = m.predict(future)

fig1 = m.plot(forecast)
fig2 = m.plot_components(forecast)

fig1.savefig(DATA_DIR + 'forecast.png')
fig2.savefig(DATA_DIR + 'components.png')

print('saved charts to ..' + DATA_DIR)
plt.title(f'Stock price of AAPL');
plt.show()
