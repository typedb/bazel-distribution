package com.vaticle.bazel.distribution.common

enum class OS(private val displayName: String) {
    WINDOWS("Windows"),
    MAC("MacOS"),
    LINUX("Linux");

    override fun toString(): String {
        return displayName
    }
}
