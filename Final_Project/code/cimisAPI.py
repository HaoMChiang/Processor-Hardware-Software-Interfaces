import requests
import datetime

def getHumidity(key, location):
    data = -1     # variable to store humidity
    now = datetime.datetime.now()     # get current date and time for API
    day = str(now.year) + '-' + str(now.month) + '-' + str(now.day)     # update the date for API
    time = now.hour - 2                                                 # index position in json for getting correct humidity
    if time == -2 or time == -1:    # if the time is 12 am or 1 am we get the data from previous
        yesterday = now - datetime.timedelta(1)
        day = str(yesterday.year) + '-' + str(yesterday.month) + '-' + str(yesterday.day)
        if time == -2:
            time = 22
        elif time == -1:
            time = 23
    result = requests.get('http://et.water.ca.gov/api/data?appKey=' + key + '&targets=' + str(location) + '&startDate=' + day + '&endDate=' + day + '&dataItems=hly-rel-hum').json()        # get the json
    data = result['Data']['Providers'][0]['Records'][time]['HlyRelHum']['Value']    # get the humidity
    while data is None:     # if the humidity is none then we get the previously available data
        time -= 1
        data = result['Data']['Providers'][0]['Records'][time]['HlyRelHum']['Value']
    return int(data)
