package com.example.app_mobile.data.model

/**
 * Định nghĩa các lệnh gửi qua BLE tới xe theo đúng giao thức Qt6:
 * - Điều khiển động cơ: F:<tốc độ>, B:<tốc độ>, L:<tốc độ>, R:<tốc độ>, S
 * - Điều khiển đèn: TL, TR, HAZ, LAMP
 */
sealed class CarCommand(val rawValue: String) {
    // Động cơ
    data class Forward(val speed: Int) : CarCommand("F:$speed")
    data class Backward(val speed: Int) : CarCommand("B:$speed")
    data class TurnLeft(val speed: Int) : CarCommand("L:$speed")
    data class TurnRight(val speed: Int) : CarCommand("R:$speed")
    object Stop : CarCommand("S")

    // Đèn / Tín hiệu
    object ToggleLeftSignal : CarCommand("TL")
    object ToggleRightSignal : CarCommand("TR")
    object ToggleHazard : CarCommand("HAZ")
    object ToggleHeadlight : CarCommand("LAMP")
}

enum class DriveDirection {
    FORWARD,
    BACKWARD,
    LEFT,
    RIGHT
}
