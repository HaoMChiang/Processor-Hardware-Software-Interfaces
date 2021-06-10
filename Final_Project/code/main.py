from PCF8574 import PCF8574_GPIO
from Adafruit_LCD1602 import Adafruit_CharLCD
import Freenove_DHT
import cimisAPI
import threading
import RPi.GPIO as GPIO
import time
import datetime

pirLed = 20       # define LED for PIR Sensor
acLed = 17        # define LED for AC
heaterLed = 27    # define LED for heater
sensorPin = 21    # define pin for PIR Sensor
doorButton = 26   # define button for door/window
degreeIncreaseButton = 19   # define button to increase temperature
degreeDecreaseButton = 13   # define button to decrease temperature
userTemperature = 75  # initial value for user defined temperature
avgTemp = 75        # average of 3 latest measured temperatures
weatherIndex = 75   # define weather index
isPirLedOn = 'OFF'  # status of the green LED
doorStatus = 'SAFE' # status of the door/window
hvacStatus = 'OFF ' # status of HVAC Status
acDisplay = False   # check whether AC is turned on
heatDisplay = False # check whether heat is turned on
isDoorOpened = False    # check whether the door is opened for display
isDoorClosed = False    # check whether the door is closed for display
pirThread = None    # thread for PIR Sensor
lcdThread = None    # thread for LCD
doorThread = None   # thread for door
dhtThread = None    # thread for DHT

# setup GPIO and PIR Sensor

GPIO.setwarnings(False)                             # set warning off
GPIO.setmode(GPIO.BCM)                              # use BCM
GPIO.setup([pirLed, acLed, heaterLed], GPIO.OUT)    # set OUTPUT mode
GPIO.setup(sensorPin, GPIO.IN)                      # set INPUT mode
GPIO.setup([doorButton, degreeIncreaseButton, degreeDecreaseButton], GPIO.IN, pull_up_down = GPIO.PUD_UP)   # set up buttons
GPIO.output([pirLed, acLed, heaterLed], False)      # turn all LEDs off

###### Thread handling PIR Sensor ######

def pir_Thread():
    global isPirLedOn
    while inPirThread:
        if GPIO.input(sensorPin) == 1 and isPirLedOn == 'OFF':  # handle the case when motion is detected and green LED is off
            isPirLedOn = 'ON '          # change the status of green LED that should be displayed on LCD to 'ON'
            GPIO.output(pirLed, True)   # turn on led
        elif GPIO.input(sensorPin) == 0 and isPirLedOn == 'ON ': # handle the case when the motion is not detected and green LED is on
            endTime = time.time() + 10  # get the time that is 10 seconds later
            while GPIO.input(sensorPin) == 0 and time.time() <= endTime and inPirThread: # check whether 10 seconds have passed and motion has been detected
                pass
            if time.time() >= endTime:  # if 10 seconds have passed
                isPirLedOn = 'OFF'      # change the status of green LED that should be displayed on LCD to 'OFF'
                GPIO.output(pirLed, False) # turn off led

###### Thread handling LCD ######

def lcd_Thread():
    global isPirLedOn
    global doorStatus
    global hvacStatus
    global weatherIndex
    global userTemperature
    global heatDisplay
    global acDisplay
    global isDoorClosed
    global isDoorOpened
    didSpecialDisplay = False # boolean variable that checks whether there is any special display
    mcp.output(3,1)     # turn on LCD backlight
    lcd.begin(16,2)     # set number of LCD lines and columns
    lcd.setCursor(0,0)  # set cursor position
    lcd.message(str(weatherIndex) + '/' + str(userTemperature) + '     D:' + doorStatus + '\n') # display temperature and door status
    lcd.message('H:' + hvacStatus + '    L:' + isPirLedOn)        # display HVAV and PIR status
    while inLcdThread:
        if isDoorOpened:                        # handle the case when door is opened
            isDoorOpened = False
            didSpecialDisplay = True
            lcd.clear()
            lcd.message('DOOR/WINDOW OPEN\n')
            lcd.message('   HVAC HALTED')
            time.sleep(3)
        elif isDoorClosed:                      # handle the case when door is closed
            isDoorClosed = False
            didSpecialDisplay = True
            lcd.clear()
            lcd.message('DOOR/WINDOW SAFE\n')
            lcd.message('   HVAC RESUME')
            time.sleep(3)
        if heatDisplay == True:                 # handle the case when heat is on
            heatDisplay = False
            didSpecialDisplay = True
            lcd.clear()
            lcd.message('    HVAC HEAT')
            time.sleep(3)
        elif acDisplay == True:                 # handle the case when AC is on
            acDisplay = False
            didSpecialDisplay = True
            lcd.clear()
            lcd.message('    HVAC AC')
            time.sleep(3)
        if didSpecialDisplay:                   # handle the case when there is special display
            didSpecialDisplay = False
            lcd.setCursor(0,0)                  # set the display back from speical display to normal display
            lcd.message(str(weatherIndex) + '/' + str(userTemperature) + '     D:' + doorStatus + '\n')
            lcd.message('H:' + hvacStatus + '    L:' + isPirLedOn)
        lcd.setCursor(0,0)                      # update normal display
        lcd.message(str(weatherIndex))
        lcd.setCursor(3,0)
        lcd.message(str(userTemperature))
        lcd.setCursor(12,0)
        lcd.message(doorStatus)
        lcd.setCursor(2,1)
        lcd.message(hvacStatus)
        lcd.setCursor(12,1)
        lcd.message(isPirLedOn)
    lcd.clear()                                 # clear LCD after exit the thread
    
###### Thread handling door/window system ######

def door(self):
    global doorStatus
    global hvacStatus
    global isDoorOpened
    global isDoorClosed
    if doorStatus == 'SAFE':        # open the door/window when door/window is closed
        doorStatus = 'OPEN'         # update the status of door that should be displayed on LCD to 'OPEN'
        hvacStatus = 'OFF '         # update the status of HVAC that should be displayed on LCD to 'OFF'
        isDoorOpened = True         # update isDoorOpened to true to trigger the if statement in LCD thread to display door status
        GPIO.output([acLed, heaterLed], False) # turn heat/AC off
    elif doorStatus == 'OPEN':      # close the door/window when door/window is opened
        doorStatus = 'SAFE'         # update the status of door that should be displayed on LCD to 'SAFE'
        isDoorClosed = True         # update isDoorClosed to true to trigger the if statement in LCD thread to display door status

###### Function that increase the desired temperature ######

def increaseTemp(self):
    global userTemperature
    if userTemperature < 85:
        userTemperature += 1

###### Function that decrease the desired temperature ######

def decreaseTemp(self):
    global userTemperature
    if userTemperature > 65:
        userTemperature -= 1

###### Thread handling DHT-11 ######

def dht_Thread(key, location):
    global hvacStatus
    global userTemperature
    global weatherIndex
    global heatDisplay
    global acDisplay
    tempList = [75] * 3   # array that keeps track of 3 latest temperatures
    mostRecentTime = -1         # latest hour used in API
    dht = Freenove_DHT.DHT(4)   # set up DHT
    sumCnt = 0
    okCnt = 0
    while inDhtThread:          # keep getting temperature and humidity
        chk = dht.readDHT11()   # set up DHT
        if (chk is 0):
            okCnt += 1
        tempList[sumCnt % 3] = dht.temperature * (9/5) + 32     # store most recent temperature
        if mostRecentTime != datetime.datetime.now().hour:      # check whether API is called in same hour if so don't need to call it again since the results are the same
            humidity = cimisAPI.getHumidity(key, location)      # get the humidity using CIMIS API
            mostRecentTime = datetime.datetime.now().hour       # update the most recent hour
        avgTemp = round((tempList[0] + tempList[1] + tempList[2]) / 3)  # average temperatures to avoid mistakes
        weatherIndex = round(avgTemp + 0.05 * humidity)                 # calculate weather index
        sumCnt += 1
        
        # update HVAC based on weather index and desired temperature
        
        if(abs(weatherIndex - userTemperature) < 3 and hvacStatus != 'OFF '):
            GPIO.output([acLed, heaterLed], False)
            hvacStatus = 'OFF '
        elif(userTemperature - weatherIndex >= 3 and hvacStatus != 'HEAT' and doorStatus == 'SAFE'):
            GPIO.output(heaterLed, True)
            heatDisplay = True
            hvacStatus = 'HEAT'
        elif(weatherIndex - userTemperature >= 3 and hvacStatus != 'AC  ' and doorStatus == 'SAFE'):
            GPIO.output(acLed, True)
            acDisplay = True
            hvacStatus = 'AC  '
        time.sleep(1)
        
if __name__ == '__main__':     # Program entrance
    print ('Program is starting...')
    # setup LCD
    PCF8574_address = 0x27  # I2C address of the PCF8574 chip.
    PCF8574A_address = 0x3F  # I2C address of the PCF8574A chip.
    # Create PCF8574 GPIO adapter.
    try:
        mcp = PCF8574_GPIO(PCF8574_address)
    except:
        try:
            mcp = PCF8574_GPIO(PCF8574A_address)
        except:
            print ('I2C Address Error !')
            exit(1)
    # Create LCD, passing in MCP GPIO adapter.
    lcd = Adafruit_CharLCD(pin_rs=0, pin_e=2, pins_db=[4,5,6,7], GPIO=mcp)
    
    key = '3acd52d8-2312-4e18-9eb3-24b65cdec7e9' # api key for cimis
    location = 78   # nearest station to me
    
    # start LCD Thread
    inLcdThread = True
    lcdThread = threading.Thread(target = lcd_Thread, daemon = True)
    lcdThread.start()
    
    # start PIR Thread
    inPirThread = True
    pirThread = threading.Thread(target = pir_Thread, daemon = True)
    pirThread.start()
    
    # start DHT Thread
    inDhtThread = True
    dhtThread = threading.Thread(target = dht_Thread, args = (key, location,), daemon = True)
    dhtThread.start()
    
    GPIO.add_event_detect(doorButton, GPIO.RISING, callback = door, bouncetime = 300)                       # detect door button
    GPIO.add_event_detect(degreeIncreaseButton, GPIO.RISING, callback = increaseTemp, bouncetime = 300)     # dectect button for increasing temperature
    GPIO.add_event_detect(degreeDecreaseButton, GPIO.RISING, callback = decreaseTemp, bouncetime = 300)     # detect button for decreasing button
    
    try:
        while True:
            time.sleep(1)       # wait 1 second

    finally:
        inPirThread = False     # end PIR Thread
        inDhtThread = False     # end DHT Thread
        inLcdThread = False     # end LCD Thread
        GPIO.output([pirLed, acLed, heaterLed], False)  # turn all LEDs off
        lcd.clear()             # clear lcd
        GPIO.cleanup()          # release GPIO
