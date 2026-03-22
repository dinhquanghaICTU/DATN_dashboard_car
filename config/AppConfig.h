#ifndef __APPCONFIG_H__
#define __APPCONFIG_H__ 

//define for LM393_speed_sensor
#define PIN_SPEED_SENSOR        23
#define LM393_HOLES_PER_REV     20
#define SPEED_CALC_INTERVAL_MS  500

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

// ── MPU6050 Temperature Sensor ─────────────────
#define MPU6050_I2C_BUS         1           // I2C bus 1 (/dev/i2c-1)
#define MPU6050_I2C_ADDR        0x68        // Địa chỉ mặc định (AD0 = GND)
#define TEMP_READ_INTERVAL_MS   5000        // Đọc mỗi 2 giây

#endif // __APPCONFIG_H__
