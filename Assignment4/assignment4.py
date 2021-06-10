import RPi.GPIO as GPIO
import time
import threading

###### set up GPIO ######

GPIO.setwarnings(False)   # disable warning
GPIO.setmode(GPIO.BCM)    # set the mode of GPIO to BCM
GPIO.setup([18, 22, 25, 27], GPIO.IN, pull_up_down = GPIO.PUD_UP)   # set the input of GPIO
GPIO.setup([5, 6, 12, 13], GPIO.OUT)   # set the output of GPIO
GPIO.output([5, 6, 12, 13], False)     # set all the LED to "OFF" initially

###### initialize variables ######

timeEndThread = 0.0   # expected time to stop the thread when 10 seconds threshold is reached
inThread = False      # boolean variable to decide whether to enter the thread or exit out of the thread
t = None              # variable for thread
toggleSpeed = [.1, .3, .5, .7, .9]   # time delay for LED
toggleIndex = 2       # always starts the blinking mode with time delay of toggleSpeed[2] which is 0.5 second

###### function handling blinking thread ######

def blink_thread(expectedEndTime):
    while inThread and time.time() < expectedEndTime:  # check whether yellow and blue buttons have been pressed again and check whether 10 seconds threshold has reached
        GPIO.output([5, 6, 12, 13], True)              # turn all the LEDs "ON"
        time.sleep(toggleSpeed[toggleIndex])           # sleep based on the time delay
        GPIO.output([5, 6, 12, 13], False)             # turn all the LEDs "OFF"
        time.sleep(toggleSpeed[toggleIndex])           # sleep based on the time delay

###### main function to keep track of the buttons press ######

while True:

    ######when buttons for yellow LED and blue LED are pressed ######

    if GPIO.input(22) == 0 and GPIO.input(27) == 0:
        if not inThread:                      # if the LEDs are not in blink mode
            inThread = True                   # set inThread to true indicating the blink_thread should be called
            timeEndThread = time.time() + 10   # expected time to end blink_thread when threshold of 10 seconds is reached
            t = threading.Thread(target=blink_thread, args=(timeEndThread,))   # call blink_thread with argument - "expected time to end the thread"
            t.daemon = True                   # set daemon to True
            t.start()                         # start the thread
            timeEndThread = 0                 # reset expected time to end the thread to 0
        else:                                  # if the LEDs are in blink mode
            inThread = False                   # set inThread to false and force blink_thread to exit
            toggleIndex = 2                    # reset the speed of blinking to default
            GPIO.output([5, 6, 12, 13], False) # turn all LEDs off
        time.sleep(.5)                     # 0.5 second time delay to provide user some time to press a button and get his finger off the button

    ###### when buttons for red LED is pressed (decrease the speed of blinking mode) ######

    elif GPIO.input(18) == 0:
        if inThread and toggleIndex < len(toggleSpeed) - 1:  # if blink_thread is running and toggling speed is within the defined range
            toggleIndex += 1                                 # decrease the speed of blinking
        time.sleep(.5)                                   # 0.5 second time delay to provide user some time to press a button and get his finger off the button

    ###### when buttons for green LED is pressed (increase the speed of blinking mode) ######

    elif GPIO.input(25) == 0:
        if inThread and toggleIndex > 0:    # if blink_thread is running and toggling speed is within the defined range
            toggleIndex -= 1                # increase the speed of blinking
        time.sleep(.5)                  #0.5 second time delay to provide user some time to press a button and get his finger off the button
