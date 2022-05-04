# jbd2mqtt

---

## What is this?

A containerized version of NodeJBD / bms-tools for easy monitoring of your JBD BMS with MQTT on Docker. My use case is for integration with Home Assistant but with MQTT your imagination is the limit. Currently only supports a serial UART connection (tested via USB) and only capable of *read only* access of the BMS.

[mickwheelz](https://github.com/mickwheelz) and [MrSurly](https://gitlab.com/MrSurly) did all the work and build the underlying tools. If you like this project go check out and star their repositories below:

- [mickwheelz](https://github.com/mickwheelz) / [NodeJBD](https://github.com/mickwheelz/NodeJBD) 
- [MrSurly](https://gitlab.com/MrSurly) / [BMS Tools](https://gitlab.com/bms-tools)



---

## Connecting to your BMS

### Compatibility

In theory this container should work with any JBD BMS however these are the confirmed working models by mickwheelz and I:

|BMS Model|Interface|Notes|Status|
|----------|---------|-----|------|
|JBD SP04S028A|UART| 150A 4s LiFePO4 BMS|✅|
|JBD SP04S28A4S|UART|100A 4s LiFePO4 BMS|✅|

### Connection

This project currently only supports a serial UART connection to the BMS. It has only been tested tested through a USB to UART serial adapter.

##### USB UART Serial Connection

The JBD BMS has a 5v TTL serial connection UART port for communication. Connect TX, RX and GND and you should be good to go. I used a CP2102 based USB adapter from amazon and made a custom cable. I think ready made adapters exist over at Overkill Solar, Current Connected or AliExpress.

##### Important Connection Notes:

- The UART port has 4 pins, GND, TX, RX and VCC. I have seen reports of VCC putting out ~10v so I would **NOT** connect anything to VCC. It is not needed for the CP2102 based USB adapter or any other adapter.
- Seeing how there is only one UART port on the BMS I don't think the USB adapter and bluetooth adapter can be used at the same time.



---

## Running the Container

### Docker Run

Here is the command to run the container using the Docker run command:

```
$ docker run -d --name=jbd2mqtt \
    --restart unless-stopped \
    -e NODEJBD_SERIALPORT=/dev/ttyUSB0 \
    -e NODEJBD_MQTTBROKER=mosquitto \
    -e NODEJBD_MQTTUSER=username \
    -e NODEJBD_MQTTPASS=password \
    --device /dev/ttyUSB0 \
    robwolff3/jbd2mqtt
```



### Docker Compose

And here is an example of running the container using docker compose:

```yaml
version: '3'
services:

  jbd2mqtt:
    container_name: jbd2mqtt
    image: robwolff3/jbd2mqtt
    restart: unless-stopped
    environment:
      NODEJBD_SERIALPORT: /dev/ttyUSB0
      NODEJBD_MQTTBROKER: mosquitto
      NODEJBD_MQTTUSER: username
      NODEJBD_MQTTPASS: password
    devices:
      - /dev/ttyUSB0
```



### Environment Variables

Lastly all the environment variables you can define. Same as the NodeJBD project.

|Env Var|Description | Example |
|----------|-----|----|
|NODEJBD_SERIALPORT|REQUIRED: Serial port your BMS is connected to|/dev/ttyUSB0|
|NODEJBD_BAUDRATE|The baud rate to use for serial communications, defaults to 9600|14400|
|NODEJBD_MQTTBROKER|The address of your MQTT Broker|192.168.0.10|
|NODEJBD_MQTTUSER|The username for your MQTT Broker|mqttUser|
|NODEJBD_MQTTPASS|The password for your MQTT Broker|mqttPass|
|NODEJBD_MQTTTOPIC|MQTT topic to publish to defaults to 'NodeJBD'|MyTopic|
|NODEJBD_POLLINGINTERVAL|How frequently to poll the controller in seconds, defaults to 10|60|
|NODEJBD_LOGLEVEL|Sets the logging level, useful for debugging|trace|



---

## Defining Sensors in Home Assistant

Here are what I would consider the more primary sensors:

```yaml
sensor:
  - platform: mqtt
    name: "Battery SOC"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['packSOC'] }}"
    unit_of_measurement: "%"
    device_class: battery

  - platform: mqtt
    name: "Battery Amp Hours"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['packBalCap'] }}"
    unit_of_measurement: "Ah"
    device_class: energy

  - platform: mqtt
    name: "Battery Volts"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['packV'] }}"
    unit_of_measurement: "V"
    device_class: voltage

  - platform: mqtt
    name: "Battery Amps"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['packA'] }}"
    unit_of_measurement: 'A'
    device_class: current


template:
  - sensor:
      - name: "Battery Watts"
        unique_id: battery_watts
        state: "{{ ( states('sensor.battery_1_volts') | float ) * ( states('sensor.battery_1_amps') | float ) }}"
        unit_of_measurement: 'W'
        device_class: power
```



And here are some of the more verbose sensors you may or may not want.

```yaml
sensor:
  - platform: mqtt
    name: "Battery Cycles"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['packCycles'] }}"

  - platform: mqtt
    name: "Battery Volts Cell-1"
    state_topic: "NodeJBD/cells"
    value_template: "{{ value_json['cell0V'] }}"
    unit_of_measurement: "V"
    device_class: voltage

  - platform: mqtt
    name: "Battery Volts Cell-2"
    state_topic: "NodeJBD/cells"
    value_template: "{{ value_json['cell1V'] }}"
    unit_of_measurement: "V"
    device_class: voltage

  - platform: mqtt
    name: "Battery Volts Cell-3"
    state_topic: "NodeJBD/cells"
    value_template: "{{ value_json['cell2V'] }}"
    unit_of_measurement: "V"
    device_class: voltage

  - platform: mqtt
    name: "Battery Volts Cell-4"
    state_topic: "NodeJBD/cells"
    value_template: "{{ value_json['cell3V'] }}"
    unit_of_measurement: "V"
    device_class: voltage


  - platform: mqtt
    name: "Battery Bal Cell-1"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatus'][0].cell0 }}"

  - platform: mqtt
    name: "Battery Bal Cell-2"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatus'][1].cell1 }}"

  - platform: mqtt
    name: "Battery Bal Cell-3"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatus'][2].cell2 }}"

  - platform: mqtt
    name: "Battery Bal Cell-4"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatus'][3].cell3 }}"

  - platform: mqtt
    name: "Battery Bal High Cell-1"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatusHigh'][0].cell0 }}"

  - platform: mqtt
    name: "Battery Bal High Cell-2"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatusHigh'][1].cell1 }}"

  - platform: mqtt
    name: "Battery Bal High Cell-3"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatusHigh'][2].cell2 }}"

  - platform: mqtt
    name: "Battery Bal High Cell-4"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['balanceStatusHigh'][3].cell3 }}"


  - platform: mqtt
    name: "Battery Cell Overvolt"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].singleCellOvervolt }}"

  - platform: mqtt
    name: "Battery Cell Undervolt"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].singleCellUndervolt }}"

  - platform: mqtt
    name: "Battery Pack Overvolt"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].packOvervolt }}"

  - platform: mqtt
    name: "Battery Pack Undervolt"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].packUndervolt }}"

  - platform: mqtt
    name: "Battery Charge Overtemp"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].chargeOvertemp }}"

  - platform: mqtt
    name: "Battery Charge Undertemp"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].chargeUndertemp }}"

  - platform: mqtt
    name: "Battery Discharge Overtemp"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].dischargeOvertemp }}"
  - platform: mqtt
    name: "Battery Discharge Undertemp"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].dischargeUndertemp }}"

  - platform: mqtt
    name: "Battery Charge Overcurrent"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].chargeOvercurrent }}"

  - platform: mqtt
    name: "Battery Discharge Overcurrent"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].dischargeOvercurrent }}"

  - platform: mqtt
    name: "Battery Short Circut"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].shortCircut }}"

  - platform: mqtt
    name: "Battery Frontend Detection IC Error"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].frontEndDetectionICError }}"

  - platform: mqtt
    name: "Battery Software Lock MOS"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['protectionStatus'].softwareLockMOS }}"

  - platform: mqtt
    name: "Battery FET Status Charging"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['FETStatus'].charging }}"

  - platform: mqtt
    name: "Battery FET Status Discharging"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['FETStatus'].discharging }}"


  - platform: mqtt
    name: "Battery Temp NTC0"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['tempSensorValues'].NTC0 }}"
    unit_of_measurement: "C"
    device_class: temperature

  - platform: mqtt
    name: "Battery Temp NTC1"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['tempSensorValues'].NTC1 }}"
    unit_of_measurement: "C"
    device_class: temperature

  - platform: mqtt
    name: "Battery Temp NTC2"
    state_topic: "NodeJBD/pack"
    value_template: "{{ value_json['tempSensorValues'].NTC2 }}"
    unit_of_measurement: "C"
    device_class: temperature
```

