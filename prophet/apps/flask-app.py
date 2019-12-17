import json
from datetime import datetime
from flask import Flask, abort
import pandas as pd
from fbprophet import Prophet

DATA_DIR = '/data/'
INPUT_CSV = DATA_DIR + 'aapl.csv'

forecast = None

app = Flask(__name__, instance_path='/apps')

def load_and_train_model(ndays):
    global forecast

    csv = pd.read_csv(INPUT_CSV)
    df = csv[['Date', 'Close']]
    df.rename(columns={'Date' : 'ds', 'Close' : 'y'}, inplace=True)

    m = Prophet(weekly_seasonality=True, daily_seasonality=True)
    m.fit(df)

    future = m.make_future_dataframe(periods=ndays)
    f = m.predict(future)
    forecast = f[['ds', 'yhat']]

def row_to_json(row):
    d = row[['ds', 'yhat']].reset_index().to_dict() 
    dt = d['ds'][0].date().strftime('%Y-%M-%d')
    closed = d['yhat'][0]
    return json.dumps({"DT": dt , "TICKER": 'AAPL_P', "CLOSED" : closed})

# == rest API ===

@app.route('/')
def index(): return "prophet rest api is running"

@app.route('/train/<int:ndays>')
def train(ndays):
    load_and_train_model(ndays)
    return "trained for {} days".format(ndays), 200

@app.route('/predict/<string:dt>')
def predict(dt):
    global forecast   

    if forecast is None:
        load_and_train_model(365)
    
    ## Workshop  TASK 3  ========================  
    #
    # Implement : SELECT * FROM forecast WHERE ds = @dt ;  dt in format 'yyyy-MM-dd'
    #


    # End workshop ======================

    if row.empty:  
        return '', 204   

    return row_to_json(row) 
 
if __name__ == '__main__':
    app.run(debug=True)

