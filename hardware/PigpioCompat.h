#pragma once

#ifdef DATN_RPI_HARDWARE

#include <pigpiod_if2.h>

#else

#include <chrono>
#include <cstdint>

// Desktop-only pigpio substitutes. They preserve the controller interfaces so
// the QML dashboard can run without a pigpio daemon or Raspberry Pi peripherals.
inline constexpr unsigned PI_INPUT = 0;
inline constexpr unsigned PI_OUTPUT = 1;
inline constexpr unsigned PI_PUD_UP = 2;
inline constexpr unsigned RISING_EDGE = 0;

using PigpioCallback = void (*)(int, unsigned, unsigned, std::uint32_t);

inline int pigpio_start(const char*, const char*) { return 0; }
inline void pigpio_stop(int) {}
inline int set_mode(int, unsigned, unsigned) { return 0; }
inline int set_pull_up_down(int, unsigned, unsigned) { return 0; }
inline int gpio_write(int, unsigned, unsigned) { return 0; }
inline int hardware_PWM(int, unsigned, unsigned, unsigned) { return 0; }
inline int callback(int, unsigned, unsigned, PigpioCallback) { return 0; }

inline std::uint32_t get_current_tick(int)
{
    using namespace std::chrono;
    return static_cast<std::uint32_t>(
        duration_cast<microseconds>(steady_clock::now().time_since_epoch()).count());
}

// Report unavailable I2C hardware on Desktop. TempSensor already handles these
// negative return values and simply leaves the displayed sensor value unchanged.
inline int i2c_open(int, unsigned, unsigned, unsigned) { return -1; }
inline int i2c_close(int, unsigned) { return 0; }
inline int i2c_read_byte_data(int, unsigned, unsigned) { return -1; }
inline int i2c_read_i2c_block_data(int, unsigned, unsigned, char*, unsigned) { return -1; }
inline int i2c_write_byte_data(int, unsigned, unsigned, unsigned) { return -1; }

#endif
