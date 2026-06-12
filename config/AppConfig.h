#ifndef __APPCONFIG_H__
#define __APPCONFIG_H__ 

//define for LM393_speed_sensor
#define PIN_SPEED_SENSOR        23
#define LM393_HOLES_PER_REV     20
#define SPEED_CALC_INTERVAL_MS  20
#define SPEED_RENDER_INTERVAL_US 50000
#define SPEED_ZERO_TIMEOUT_MS   350
#define SPEED_MIN_PULSE_US      2500
#define SPEED_REALISTIC_SCALE   55.0f

//config for motor

// L298N — Motor trái
// L298N — Motor trái
#define PIN_MOTOR_IN1       24      // BCM 24 = Pin 18
#define PIN_MOTOR_IN2       25      // BCM 25 = Pin 22
#define PIN_MOTOR_ENA       12      // BCM 12 = Pin 32 (Hardware PWM)

// L298N — Motor phải
#define PIN_MOTOR_IN3       20      // BCM 20 = Pin 38
#define PIN_MOTOR_IN4       21      // BCM 21 = Pin 40
#define PIN_MOTOR_ENB       13      // BCM 13 = Pin 33 (Hardware PWM)

#define MOTOR_PWM_FREQ      1000
#define MOTOR_DEFAULT_SPEED 70
#define MOTOR_LEFT_INVERTED  0
#define MOTOR_RIGHT_INVERTED 0
#define MOTOR_LEFT_TRIM_PERCENT  100
#define MOTOR_RIGHT_TRIM_PERCENT 100

// Lights / turn signals
// BCM numbering. BCM 5 = physical pin 29, BCM 6 = physical pin 31.
// Drive relay/MOSFET inputs only; do not power bulbs directly from GPIO.
#define PIN_LIGHT_LEFT      5
#define PIN_LIGHT_RIGHT     6
#define LIGHT_BLINK_INTERVAL_MS 500

// BMP280 temperature sensor
#define BMP280_I2C_BUS          1           // I2C bus 1 (/dev/i2c-1)
#define BMP280_I2C_ADDR         0x76        // Default BMP280 address (SDO = GND)
#define BMP280_I2C_ADDR_ALT     0x77        // Alternate address (SDO = VCC)
#define TEMP_READ_INTERVAL_MS   1000

#endif // __APPCONFIG_H__
