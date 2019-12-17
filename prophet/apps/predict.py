import sys
import pandas as pd
from fbprophet import Prophet

DATA_DIR = '/data/'
INPUT_CSV = DATA_DIR + 'aapl.csv'

if (len(sys.argv) < 2):
    print("Usage : {} days".format(sys.argv[0]))
    sys.exit()

predict_days = int(sys.argv[1])

print("read input data " + INPUT_CSV)
csv = pd.read_csv(INPUT_CSV)

df = csv[['Date', 'Close']]
df.rename(columns={'Date' : 'ds', 'Close' : 'y'}, inplace=True)

print('train model ..')
m = Prophet(weekly_seasonality=True, daily_seasonality=True)
m.fit(df)

print("predict for {} days".format(predict_days))
future = m.make_future_dataframe(periods=predict_days)
forecast = m.predict(future)

fig1 = m.plot(forecast)
fig2 = m.plot_components(forecast)

fig1.savefig(DATA_DIR + 'forecast.png')
fig2.savefig(DATA_DIR + 'components.png')

print('saved charts to ..' + DATA_DIR)
