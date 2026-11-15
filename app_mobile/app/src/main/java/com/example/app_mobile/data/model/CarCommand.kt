package com.example.app_mobile.data.model

sealed class CarCommand(val rawValue: String) {

    data class Forward(val speed: Int) : CarCommand("F:$speed")
    data class Backward(val speed: Int) : CarCommand("B:$speed")
    data class TurnLeft(val speed: Int) : CarCommand("L:$speed")
    data class TurnRight(val speed: Int) : CarCommand("R:$speed")
    object Stop : CarCommand("S")

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
